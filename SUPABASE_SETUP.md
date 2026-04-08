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
