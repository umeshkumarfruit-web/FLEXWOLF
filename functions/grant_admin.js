"use strict";

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

async function main() {
  const email = process.argv[2]?.trim().toLowerCase();
  if (!email || !email.includes("@")) {
    throw new Error("Usage: node grant_admin.js admin@example.com");
  }
  initializeApp({ credential: applicationDefault() });
  const auth = getAuth();
  const user = await auth.getUserByEmail(email);
  await auth.setCustomUserClaims(user.uid, {
    ...(user.customClaims || {}),
    admin: true,
    role: "admin",
  });
  console.log("Admin claim granted to Firebase UID:", user.uid);
  console.log("Sign out and sign back in to refresh the ID token.");
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
