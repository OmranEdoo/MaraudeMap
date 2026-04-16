# Supabase Setup

Cette application a maintenant un socle Supabase, mais elle reste en mode demo tant que les cles ne sont pas renseignees.

## 1. Creer le projet

1. Cree un projet sur le dashboard Supabase.
2. Recupere `Project URL` et `anon public key`.

## 2. Creer la base

1. Ouvre `SQL Editor`.
2. Execute le contenu de [supabase/schema.sql](supabase/schema.sql).

Ce schema cree :
- `profiles`
- `maraudes`
- les triggers `updated_at`
- les policies RLS

## 3. Creer les premiers utilisateurs

1. Dans `Authentication > Users`, cree les comptes membres.
2. Pour chaque utilisateur cree, ajoute ensuite sa ligne dans `profiles`.

Exemple :

```sql
insert into public.profiles (id, email, full_name, association_name)
values (
  'UUID_DU_USER',
  'association.tayba@gmail.com',
  'Omran EDOO',
  'TAYBA'
);
```

## 4. Lancer l'application avec les cles

Avant le premier test d'inscription par email, configure aussi le redirect d'authentification dans Supabase :

1. Ouvre `Authentication > URL Configuration`.
2. Remplace `Site URL` par `maraudemap://login-callback/` au lieu de `http://localhost:3000`.
3. Ajoute aussi `maraudemap://login-callback/` dans `Additional Redirect URLs`.
4. Ouvre `Authentication > Email Templates` et verifie que les templates de confirmation / recovery utilisent bien `{{ .ConfirmationURL }}`. Si un template personnalise utilise `{{ .SiteURL }}`, `localhost:3000` peut continuer d'apparaitre dans les emails.
5. Si tu avais deja envoye un email d'inscription avant ce reglage, renvoie un nouvel email : les anciens liens qui pointent vers `localhost:3000` ou qui ont expire continueront d'echouer.

Apres une modification du deep link mobile, fais un vrai redemarrage de l'application (`flutter run` ou reinstallation) plutot qu'un simple hot reload.

Utilise des `dart-define` :

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://gmprlorpsxoljtedmjbn.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_zqYHgLmDRW-2_HfWNvokpg_mF_C2WAR
```

## 5. Ce qui est deja prepare dans le code

- Initialisation Supabase : [lib/services/supabase_bootstrap.dart](lib/services/supabase_bootstrap.dart)
- Config runtime : [lib/config/supabase_config.dart](lib/config/supabase_config.dart)
- Auth email / mot de passe : [lib/services/auth_service.dart](lib/services/auth_service.dart)
- Mapping maraudes <-> base : [lib/models/maraude.dart](lib/models/maraude.dart)
- Repository Supabase pour les maraudes : [lib/repositories/supabase_maraude_repository.dart](lib/repositories/supabase_maraude_repository.dart)

## 6. Prochaine etape recommandee

La suite logique est de remplacer les listes en dur de la carte et de la liste par `SupabaseMaraudeRepository`, puis de brancher la creation et la modification sur la table `maraudes`.

## 7. Build Android de test interne

Le package Android est prepare pour `fr.tayba.maraudemap`.

### Creer le keystore de publication

```powershell
keytool -genkeypair -v `
  -keystore android\\upload-keystore.jks `
  -alias upload `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000
```

### Creer `android/key.properties`

Tu peux partir de [android/key.properties.example](android/key.properties.example) et creer un fichier `android/key.properties` :

```properties
storePassword=TON_MOT_DE_PASSE_KEYSTORE
keyPassword=TON_MOT_DE_PASSE_CLE
keyAlias=upload
storeFile=upload-keystore.jks
```

### Generer le bundle Android pour Google Play

```powershell
flutter build appbundle --release `
  --dart-define=SUPABASE_URL=https://gmprlorpsxoljtedmjbn.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_zqYHgLmDRW-2_HfWNvokpg_mF_C2WAR
```

Le fichier a envoyer sur Google Play sera :

`build\app\outputs\bundle\release\app-release.aab`

### Envoyer sur Google Play en test interne

1. Cree l'application `fr.tayba.maraudemap` dans Play Console.
2. Va dans `Testing > Internal testing`.
3. Ajoute tes testeurs.
4. Uploade `app-release.aab`.
5. Publie la release de test, puis partage le lien d'invitation.
