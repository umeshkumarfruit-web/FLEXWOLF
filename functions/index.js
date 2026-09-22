"use strict";

const crypto = require("node:crypto");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const region = "us-central1";
const shopifyStoreDomain = defineString("SHOPIFY_STORE_DOMAIN");
const shopifyApiKey = defineString("SHOPIFY_API_KEY");
const shopifyApiSecret = defineSecret("SHOPIFY_API_SECRET");
const shopifyScopes = defineString("SHOPIFY_SCOPES", {
  default: "read_products,write_products,read_orders,read_customers,write_customers",
});
const shopifyAdminApiVersion = defineString("SHOPIFY_ADMIN_API_VERSION", {
  default: "2026-07",
});
const shopifyRevealAccessToken = defineString("SHOPIFY_REVEAL_ACCESS_TOKEN", {
  default: "false",
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

exports.health = onRequest({ region }, (request, response) => {
  setCors(response);
  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return;
  }

  response.json({
    ok: true,
    service: "flexwolf-firebase-functions",
  });
});

exports.syncCustomerAccount = onCall(
  { region, secrets: [shopifyApiSecret] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in before syncing an account.");
    }

    const email = String(request.auth.token.email || "").trim().toLowerCase();
    if (!email) {
      throw new HttpsError("failed-precondition", "The Firebase account has no email address.");
    }

    const firstName = cleanOptionalText(request.data?.firstName, 80);
    const lastName = cleanOptionalText(request.data?.lastName, 80);
    const customer = await findOrCreateShopifyCustomer({
      email,
      firstName,
      lastName,
    });
    const now = FieldValue.serverTimestamp();
    const userRef = getFirestore().collection("users").doc(request.auth.uid);
    const existing = await userRef.get();
    await userRef.set(
      {
        uid: request.auth.uid,
        email,
        firstName: firstName || customer.firstName || null,
        lastName: lastName || customer.lastName || null,
        displayName: [
          firstName || customer.firstName,
          lastName || customer.lastName,
        ].filter(Boolean).join(" ") || email,
        shopifyCustomerId: customer.id,
        authProvider: "firebase_password",
        updatedAt: now,
        ...(existing.exists ? {} : { createdAt: now }),
      },
      { merge: true },
    );

    return {
      uid: request.auth.uid,
      email,
      firstName: firstName || customer.firstName || null,
      lastName: lastName || customer.lastName || null,
      displayName: [
        firstName || customer.firstName,
        lastName || customer.lastName,
      ].filter(Boolean).join(" ") || email,
      shopifyCustomerId: customer.id,
    };
  },
);


exports.shopifyAuthStart = onRequest({ region }, async (request, response) => {
  if (!await requireAdminRequest(request, response)) return;
  setCors(response);
  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return;
  }

  if (request.method !== "GET") {
    response.status(405).json({ error: "method_not_allowed" });
    return;
  }

  try {
    const domain = normalizeShopDomain(
      String(request.query.shop || shopifyStoreDomain.value()).trim(),
    );
    const apiKey = requiredParam(shopifyApiKey, "SHOPIFY_API_KEY");
    const scopes = shopifyScopes.value().trim();
    const redirectUri = getShopifyRedirectUri(request);
    const state = crypto.randomBytes(16).toString("hex");
    const authUrl = new URL(`https://${domain}/admin/oauth/authorize`);
    authUrl.searchParams.set("client_id", apiKey);
    authUrl.searchParams.set("scope", scopes);
    authUrl.searchParams.set("redirect_uri", redirectUri);
    authUrl.searchParams.set("state", state);

    response.json({ authUrl: authUrl.toString(), state, redirectUri });
  } catch (error) {
    response.status(500).json({
      error: "configuration_error",
      message: error instanceof Error ? error.message : "Missing configuration",
    });
  }
});

exports.shopifyAuthCallback = onRequest({ region, secrets: [shopifyApiSecret] }, async (request, response) => {
  setCors(response);
  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return;
  }

  if (request.method !== "GET") {
    response.status(405).json({ error: "method_not_allowed" });
    return;
  }

  const { shop, code, hmac } = request.query;
  if (!shop || !code || !hmac) {
    response.status(400).json({ error: "missing_oauth_callback_params" });
    return;
  }

  try {
    const apiKey = requiredParam(shopifyApiKey, "SHOPIFY_API_KEY");
    const apiSecret = requiredParam(shopifyApiSecret, "SHOPIFY_API_SECRET");
    if (!isValidShopifyHmac(request.query, apiSecret)) {
      response.status(401).json({ error: "invalid_hmac" });
      return;
    }

    const domain = normalizeShopDomain(String(shop));
    const tokenResponse = await fetch(`https://${domain}/admin/oauth/access_token`, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        client_id: apiKey,
        client_secret: apiSecret,
        code,
      }),
    });
    const payload = await tokenResponse.json();
    if (!tokenResponse.ok) {
      response.status(tokenResponse.status).json(payload);
      return;
    }

    response.json({
      shop: domain,
      accessToken: "redacted",
      accessTokenLast4: last4(payload.access_token),
      scope: payload.scope,
      expiresIn: payload.expires_in,
      refreshToken: "redacted",
      refreshTokenExpiresIn: payload.refresh_token_expires_in,
      note: tokenRevealNote(),
    });
  } catch (error) {
    response.status(502).json({
      error: "shopify_token_exchange_failed",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

exports.shopifyGenerateAdminAccessToken = onRequest({ region, secrets: [shopifyApiSecret] }, async (request, response) => {
  if (!await requireAdminRequest(request, response)) return;
  if (request.method !== "POST") {
    response.status(405).json({ error: "method_not_allowed" });
    return;
  }

  try {
    const domain = normalizeShopDomain(
      String(request.body?.shop || request.query.shop || shopifyStoreDomain.value()).trim(),
    );
    const apiKey = requiredParam(shopifyApiKey, "SHOPIFY_API_KEY");
    const apiSecret = requiredParam(shopifyApiSecret, "SHOPIFY_API_SECRET");
    const tokenResponse = await fetch(`https://${domain}/admin/oauth/access_token`, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "client_credentials",
        client_id: apiKey,
        client_secret: apiSecret,
      }),
    });
    const payload = await tokenResponse.json();
    if (!tokenResponse.ok) {
      response.status(tokenResponse.status).json(payload);
      return;
    }

    response.json({
      shop: domain,
      accessToken: maybeRevealToken(payload.access_token),
      accessTokenLast4: last4(payload.access_token),
      expiresIn: payload.expires_in,
      scope: payload.scope,
      note: tokenRevealNote(),
    });
  } catch (error) {
    response.status(502).json({
      error: "shopify_client_credentials_exchange_failed",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

exports.shopifyProducts = onRequest({ region, secrets: [shopifyApiSecret] }, async (request, response) => {
  if (!await requireAdminRequest(request, response)) return;
  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return;
  }

  if (request.method !== "GET") {
    response.status(405).json({ error: "method_not_allowed" });
    return;
  }

  const first = clampInt(request.query.first, 1, 50, 10);
  const query = `
    query Products($first: Int!) {
      products(first: $first) {
        edges {
          node {
            id
            title
            handle
            status
            featuredImage {
              url
              altText
            }
            variants(first: 10) {
              edges {
                node {
                  id
                  title
                  sku
                  price
                }
              }
            }
          }
        }
      }
    }
  `;

  await proxyAdminGraphql(response, query, { first });
});

exports.shopifyAdminGraphql = onRequest({ region, secrets: [shopifyApiSecret] }, async (request, response) => {
  if (!await requireAdminRequest(request, response)) return;
  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return;
  }

  if (request.method !== "POST") {
    response.status(405).json({ error: "method_not_allowed" });
    return;
  }

  const { query, variables } = request.body || {};
  if (typeof query !== "string" || query.trim().length === 0) {
    response.status(400).json({ error: "missing_graphql_query" });
    return;
  }

  await proxyAdminGraphql(response, query, variables || {});
});

async function requireAdminRequest(request, response) {
  setCors(response);
  if (request.method === "OPTIONS") {
    response.status(204).send("");
    return false;
  }
  const match = /^Bearer (.+)$/i.exec(request.get("authorization") || "");
  if (!match) {
    response.status(401).json({ error: "admin_auth_required" });
    return false;
  }
  try {
    const claims = await getAuth().verifyIdToken(match[1], true);
    if (claims.admin !== true) {
      response.status(403).json({ error: "admin_role_required" });
      return false;
    }
    return true;
  } catch (_) {
    response.status(401).json({ error: "invalid_admin_token" });
    return false;
  }
}


function requireCallableAdmin(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in as admin.");
  if (request.auth.token.admin !== true) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }
}

function checkedPrice(value) {
  const price = Number(value);
  if (!Number.isFinite(price) || price <= 0 || price > 10000000) {
    throw new HttpsError("invalid-argument", "Enter a valid positive price.");
  }
  return price.toFixed(2);
}

function checkedGid(value, type) {
  const id = String(value || "");
  if (!new RegExp("^gid://shopify/" + type + "/[0-9]+$").test(id)) {
    throw new HttpsError("invalid-argument", "Invalid Shopify " + type + " ID.");
  }
  return id;
}

function shopifyMutationResult(data, field) {
  const result = data[field];
  if (!result || result.userErrors?.length) {
    throw new HttpsError(
      "failed-precondition",
      result?.userErrors?.map((e) => e.message).join("; ") || "Shopify rejected the change.",
    );
  }
  return result;
}

exports.adminOperations = onCall(
  { region, secrets: [shopifyApiSecret] },
  async (request) => {
    requireCallableAdmin(request);
    const action = String(request.data?.action || "");
    if (action === "products") {
      const data = await callShopifyAdminGraphql(
        `query { products(first: 30, sortKey: UPDATED_AT, reverse: true) {
          nodes { id title status variants(first: 20) { nodes { id title price } } }
        } }`, {},
      );
      return { items: data.products?.nodes || [] };
    }
    if (action === "orders") {
      const data = await callShopifyAdminGraphql(
        `query { orders(first: 30, sortKey: CREATED_AT, reverse: true) {
          nodes { id name createdAt displayFinancialStatus displayFulfillmentStatus
            totalPriceSet { shopMoney { amount currencyCode } } }
        } }`, {},
      );
      return { items: data.orders?.nodes || [] };
    }
    if (action === "users") {
      const page = await getAuth().listUsers(100);
      return { items: page.users.map((u) => ({
        uid: u.uid, email: u.email || "", disabled: u.disabled,
      })) };
    }
    if (action === "createProduct") {
      const title = cleanOptionalText(request.data?.title, 180);
      if (!title) throw new HttpsError("invalid-argument", "Product title is required.");
      const price = checkedPrice(request.data?.price);
      // Create as draft so a failed price update never publishes a free item.
      const created = shopifyMutationResult(await callShopifyAdminGraphql(
        `mutation ($product: ProductCreateInput!) {
          productCreate(product: $product) {
            product { id title status variants(first: 1) { nodes { id } } }
            userErrors { field message }
          }
        }`,
        { product: { title, status: "DRAFT" } },
      ), "productCreate").product;
      const variantId = created?.variants?.nodes?.[0]?.id;
      if (!variantId) {
        throw new HttpsError("failed-precondition", "Product draft created, but no default variant was returned. Check Shopify Admin.");
      }
      shopifyMutationResult(await callShopifyAdminGraphql(
        `mutation ($productId: ID!, $variants: [ProductVariantsBulkInput!]!) {
          productVariantsBulkUpdate(productId: $productId, variants: $variants) {
            product { id } userErrors { field message }
          }
        }`,
        { productId: created.id, variants: [{ id: variantId, price }] },
      ), "productVariantsBulkUpdate");
      await recordAdminAction(request, action, { productId: created.id });
      return { product: created, price, status: "DRAFT" };
    }
    if (action === "updatePrice") {
      const productId = checkedGid(request.data?.productId, "Product");
      const variantId = checkedGid(request.data?.variantId, "ProductVariant");
      const price = checkedPrice(request.data?.price);
      shopifyMutationResult(await callShopifyAdminGraphql(
        `mutation ($productId: ID!, $variants: [ProductVariantsBulkInput!]!) {
          productVariantsBulkUpdate(productId: $productId, variants: $variants) {
            product { id } userErrors { field message }
          }
        }`,
        { productId, variants: [{ id: variantId, price }] },
      ), "productVariantsBulkUpdate");
      await recordAdminAction(request, action, { productId, variantId, price });
      return { ok: true };
    }
    if (action === "sendPush") {
      const title = cleanOptionalText(request.data?.title, 100);
      const body = cleanOptionalText(request.data?.body, 500);
      if (!title || !body) {
        throw new HttpsError("invalid-argument", "Title and message are required.");
      }
      const messageId = await getMessaging().send({
        topic: "flexwolf_customers",
        notification: { title, body },
      });
      await recordAdminAction(request, action, { messageId, title });
      return { messageId };
    }
    throw new HttpsError("invalid-argument", "Unknown admin action.");
  },
);

exports.registerCustomerPush = onCall({ region }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const token = String(request.data?.token || "");
  if (token.length < 20 || token.length > 4096) {
    throw new HttpsError("invalid-argument", "Invalid push token.");
  }
  await getMessaging().subscribeToTopic([token], "flexwolf_customers");
  return { ok: true };
});

exports.removeCustomerPush = onCall({ region }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const token = String(request.data?.token || "");
  if (token.length >= 20 && token.length <= 4096) {
    await getMessaging().unsubscribeFromTopic([token], "flexwolf_customers");
  }
  return { ok: true };
});

async function recordAdminAction(request, action, details) {
  await getFirestore().collection("adminAudit").add({
    uid: request.auth.uid,
    action,
    details,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function proxyAdminGraphql(response, query, variables) {
  let endpoint;
  let token;
  try {
    const domain = requiredParam(shopifyStoreDomain, "SHOPIFY_STORE_DOMAIN");
    token = await getShopifyAdminAccessToken();
    const apiVersion = shopifyAdminApiVersion.value();
    endpoint = `https://${normalizeShopDomain(domain)}/admin/api/${apiVersion}/graphql.json`;
  } catch (error) {
    response.status(500).json({
      error: "configuration_error",
      message: error instanceof Error ? error.message : "Missing configuration",
    });
    return;
  }

  try {
    const shopifyResponse = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": token,
      },
      body: JSON.stringify({ query, variables }),
    });

    const payload = await shopifyResponse.json();
    response.status(shopifyResponse.status).json(payload);
  } catch (error) {
    response.status(502).json({
      error: "shopify_request_failed",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

async function findOrCreateShopifyCustomer({ email, firstName, lastName }) {
  const lookup = await callShopifyAdminGraphql(
    `query CustomerByEmail($query: String!) {
      customers(first: 1, query: $query) {
        nodes { id email firstName lastName }
      }
    }`,
    { query: `email:${email}` },
  );
  const existing = lookup.customers?.nodes?.[0];
  if (existing) {
    return existing;
  }

  const created = await callShopifyAdminGraphql(
    `mutation CreateCustomer($input: CustomerInput!) {
      customerCreate(input: $input) {
        customer { id email firstName lastName }
        userErrors { field message }
      }
    }`,
    {
      input: {
        email,
        ...(firstName ? { firstName } : {}),
        ...(lastName ? { lastName } : {}),
      },
    },
  );
  const result = created.customerCreate;
  if (!result?.customer || result.userErrors?.length) {
    const message = result?.userErrors?.map((error) => error.message).join("; ") ||
      "Shopify did not create the customer.";
    throw new HttpsError("failed-precondition", message);
  }
  return result.customer;
}


let cachedShopifyToken;
let cachedShopifyTokenExpiry = 0;

async function getShopifyAdminAccessToken() {
  if (cachedShopifyToken && Date.now() < cachedShopifyTokenExpiry) {
    return cachedShopifyToken;
  }
  const domain = normalizeShopDomain(
    requiredParam(shopifyStoreDomain, "SHOPIFY_STORE_DOMAIN"),
  );
  const clientId = requiredParam(shopifyApiKey, "SHOPIFY_API_KEY");
  const clientSecret = requiredParam(shopifyApiSecret, "SHOPIFY_API_SECRET");
  let response;
  try {
    response = await fetch(`https://${domain}/admin/oauth/access_token`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "client_credentials",
        client_id: clientId,
        client_secret: clientSecret,
      }),
    });
  } catch (_) {
    throw new HttpsError("unavailable", "Shopify token service is unavailable.");
  }
  const payload = await response.json();
  if (!response.ok || typeof payload.access_token !== "string") {
    throw new HttpsError(
      "failed-precondition",
      "Shopify client credentials grant failed. Check app installation and scopes.",
    );
  }
  cachedShopifyToken = payload.access_token;
  cachedShopifyTokenExpiry = Date.now() +
    Math.max(60, Number(payload.expires_in || 3600) - 300) * 1000;
  return cachedShopifyToken;
}

async function callShopifyAdminGraphql(query, variables) {
  const domain = normalizeShopDomain(
    requiredParam(shopifyStoreDomain, "SHOPIFY_STORE_DOMAIN"),
  );
  const token = await getShopifyAdminAccessToken();
  const endpoint = `https://${domain}/admin/api/${shopifyAdminApiVersion.value()}/graphql.json`;
  let shopifyResponse;
  try {
    shopifyResponse = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Shopify-Access-Token": token,
      },
      body: JSON.stringify({ query, variables }),
    });
  } catch (error) {
    throw new HttpsError(
      "unavailable",
      error instanceof Error ? error.message : "Shopify is unavailable.",
    );
  }

  const payload = await shopifyResponse.json();
  if (!shopifyResponse.ok || payload.errors?.length) {
    const message = payload.errors?.map((error) => error.message).join("; ") ||
      `Shopify returned HTTP ${shopifyResponse.status}.`;
    throw new HttpsError("failed-precondition", message);
  }
  return payload.data || {};
}


function getShopifyRedirectUri(request) {
  const host = request.get("x-forwarded-host") || request.get("host");
  const protocol = request.get("x-forwarded-proto") || "https";
  return `${protocol}://${host}/shopifyAuthCallback`;
}

function isValidShopifyHmac(query, secret) {
  const providedHmac = String(query.hmac || "");
  const message = Object.keys(query)
    .filter((key) => key !== "hmac" && key !== "signature")
    .sort()
    .map((key) => `${key}=${Array.isArray(query[key]) ? query[key].join(",") : query[key]}`)
    .join("&");
  const digest = crypto.createHmac("sha256", secret).update(message).digest("hex");
  return timingSafeEqualHex(digest, providedHmac);
}

function timingSafeEqualHex(left, right) {
  const leftBuffer = Buffer.from(left, "hex");
  const rightBuffer = Buffer.from(right, "hex");
  return leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function maybeRevealToken(token) {
  if (!token) {
    return undefined;
  }
  return shouldRevealAccessToken() ? token : "redacted";
}

function shouldRevealAccessToken() {
  return shopifyRevealAccessToken.value().toLowerCase() === "true";
}

function tokenRevealNote() {
  if (shouldRevealAccessToken()) {
    return "Token is visible because SHOPIFY_REVEAL_ACCESS_TOKEN=true. Save it as Firebase secret SHOPIFY_ADMIN_ACCESS_TOKEN, then set SHOPIFY_REVEAL_ACCESS_TOKEN=false.";
  }
  return "Token generated but redacted. Temporarily set SHOPIFY_REVEAL_ACCESS_TOKEN=true only during setup if you need to copy it into SHOPIFY_ADMIN_ACCESS_TOKEN.";
}

function last4(value) {
  if (!value || value.length < 4) {
    return undefined;
  }
  return value.slice(-4);
}

function setCors(response) {
  for (const [header, value] of Object.entries(corsHeaders)) {
    response.set(header, value);
  }
}

function requiredParam(param, name) {
  const value = param.value().trim();
  if (!value) {
    throw new Error(`${name} is not configured.`);
  }
  return value;
}

function normalizeShopDomain(domain) {
  return domain.replace(/^https?:\/\//i, "").replace(/\/+$/g, "");
}

function clampInt(value, min, max, fallback) {
  const parsed = Number.parseInt(String(value || ""), 10);
  if (!Number.isFinite(parsed)) {
    return fallback;
  }
  return Math.min(Math.max(parsed, min), max);
}

function cleanOptionalText(value, maxLength) {
  if (typeof value !== "string") {
    return undefined;
  }
  const normalized = value.trim();
  if (!normalized) {
    return undefined;
  }
  return normalized.slice(0, maxLength);
}




