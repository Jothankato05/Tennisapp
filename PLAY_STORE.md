# Publishing Veritas Tennis on Google Play

Everything Google asks for is prepared. You need a Google Play developer
account, then you upload the bundle and fill in the forms below. Each step
works from a phone browser, but a laptop is easier.

**What you need**

| Item | Where |
| --- | --- |
| Signed app bundle | `VeritasTennis-1.1.0-playstore.aab` (sent in the chat; not stored in GitHub) |
| Upload key + passwords | `veritas-tennis-upload.jks` and `upload-key-KEEP-SECRET.txt` (sent in the chat). Save both privately, e.g. in Google Drive. **Never** put them in GitHub. |
| Store text | [`store/listing.md`](store/listing.md) |
| Icon, feature graphic, screenshots | [`store/`](store) |
| Privacy policy URL | https://github.com/Jothankato05/Tennisapp/blob/ccr-d8e5d177-mi4rh1/PRIVACY.md |

---

## 1. Create a developer account (one time)

1. Go to <https://play.google.com/console/signup> with the Google account that should own the app.
2. Choose **Yourself** (personal) or **An organisation**:
   - **Personal:** needs ID verification and a one-time **US$25** fee. New personal accounts must run a
     **closed test with at least 12 testers for 14 days in a row** before the app can go public (step 6).
   - **Organisation** (e.g. if the university or a registered club publishes it): needs a D-U-N-S number,
     but skips the 12-tester rule.
3. Finish verification. Google can take a few days to approve it.

## 2. Create the app

Play Console › **Create app**:

- App name: **Veritas Tennis**
- Default language: **English (United Kingdom) – en-GB**
- App or game: **App** · Free or paid: **Free**
- Tick the declarations and click **Create app**.

## 3. Fill in "App content" (Policy › App content)

| Section | Answer |
| --- | --- |
| Privacy policy | Paste the privacy policy URL above. |
| App access | **All functionality is available without special access** (no login). |
| Ads | **No, my app does not contain ads.** |
| Content rating | Start questionnaire → choose the non-game category **Utility, Productivity, Communication, or Other**. Violence, sexuality, language, controlled substances, gambling: **No**. "Does the app allow users to interact or exchange content?" **Yes** (club members share player names and results). Shares location: **No**. Digital purchases: **No**. Expected rating: **Everyone / PEGI 3**. |
| Target audience | **18 and over**. "Could the app unintentionally appeal to children?" **No**. |
| News app | **No** |
| Government app | **No** |
| Financial features | **None** |
| Health apps | **No** |
| Advertising ID | **No**. The app does not use the advertising ID. |
| Data safety | See below. |

### Data safety answers

- Does your app collect or share any of the required user data types? **Yes**
- Is all user data encrypted in transit? **Yes**
- Do you provide a way for users to request that their data is deleted? **Yes**

Data types to tick (all **Collected: Yes**, **Shared: No**, **Processed ephemerally: No**,
**Optional**, purpose **App functionality**):

| Category | Data type | Why |
| --- | --- | --- |
| Personal info | **Name** | Player names are synced to the club when the user joins a club. |
| Personal info | **Phone number** | An optional field on player profiles, synced with the club. |
| App activity | **Other user-generated content** | Match results and tournaments synced with the club. |

Supabase hosts the data for us as a service provider, so this counts as "collected" but not "shared".

## 4. Store listing (Grow users › Store presence › Main store listing)

Copy the text from [`store/listing.md`](store/listing.md) and upload:

- App icon: `store/icon-512.png`
- Feature graphic: `store/feature-graphic.png`
- Phone screenshots: everything in `store/screenshots/`

Category: **Sports**. Add your contact email.

> **About the university's name:** Google may ask you to show that you're allowed
> to use "Veritas University" in the listing. Keep a short letter or email of
> permission from the Sports Unit (or the Student Affairs office) ready. If the app isn't officially endorsed,
> add "Unofficial app for Veritas University players" to the full description.

## 5. Try it yourself first (Internal testing, optional but quick)

Testing › **Internal testing** › Create new release:

1. When asked about app signing, keep **"Let Google manage and protect your app signing key"** (recommended).
2. Upload `VeritasTennis-1.1.0-playstore.aab`.
3. Release name `1.1.0`. Release notes: *First release: live scoring, ladder, tournaments, club sync and training.*
4. Save, review, **Start rollout**. Add your own Gmail under **Testers**, open the opt-in link on your phone
   and install from the Play Store. This usually works within minutes.

Play may warn that the bundle "contains native code" without debug symbols. That warning is safe to ignore:
it only affects how crash reports are displayed.

## 6. Closed test with 12+ testers (personal accounts)

Testing › **Closed testing** › Create track (e.g. "Veritas club"):

1. Create a release with the same `.aab` and roll it out.
2. **Testers:** add an email list with at least 12 club members' Gmail addresses (more is safer, in case
   some never accept). Share the opt-in link in the club WhatsApp group.
3. Testers must **accept the invite and keep the app installed for 14 days**.
4. After 14 days, go to **Dashboard › Apply for production access** and answer the short questions about the test.

## 7. Go live (Production)

Production › **Create new release** › add the same bundle (or a newer one) › Countries: **Nigeria** (add more
if you like) › **Send for review**. Google's review usually takes from a few hours to a few days. After that,
students can search for "Veritas Tennis" on the Play Store.

---

## Releasing updates later

1. Increase the version in `pubspec.yaml`, e.g. `version: 1.1.1+3`. The number after `+` must go up every time.
2. Build a bundle signed with the **same upload key**. Two ways:
   - **GitHub Actions (easiest):** add these repository secrets once (GitHub › Settings › Secrets and
     variables › Actions): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
     `ANDROID_KEY_PASSWORD` (the values are in `upload-key-KEEP-SECRET.txt`). Every push then produces a
     signed `VeritasTennis.aab` under the run's **Artifacts**.
   - **On a computer with Flutter:** create `android/key.properties` (see the README) and run
     `flutter build appbundle --release`.
3. Upload it as a new release on the track you want.

If the upload key is ever lost, Play App Signing lets you request an upload-key reset from Google Play
support. You can't lose the app this way.
