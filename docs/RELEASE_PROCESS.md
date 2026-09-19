# FLEXWOLF Release Process

## Versioning

FLEXWOLF uses Semantic Versioning with Flutter build numbers:

```text
MAJOR.MINOR.PATCH+BUILD
```

Example:

```text
1.0.0+1
```

Update only `pubspec.yaml` for release version changes.

## Release Notes

Use `.github/release_notes_template.md` for every release:

```markdown
# FLEXWOLF vVERSION

## Features

- 

## Fixes

- 

## Known Issues

- 
```

## Android Release

1. Update `pubspec.yaml`.
2. Run `flutter analyze`.
3. Run `flutter test`.
4. Run `flutter build apk --debug`.
5. Run `flutter build appbundle`.
6. Upload the AAB to the Play Console when signing is configured.

## iOS Release

iOS release automation is prepared only in Phase 11.2. Final signed distribution must wait for Apple signing assets and App Store Connect secrets.
