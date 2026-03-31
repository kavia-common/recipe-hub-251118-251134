# Recipe Hub Database Container

This PostgreSQL container stores all relational data for the Recipe Hub application.

## Startup and initialization strategy

The database uses the existing `startup.sh` bootstrap flow and now adds two idempotent SQL bootstrap files:

- `init_recipe_hub.sql` - schema, enums, triggers, views, indexes
- `seed_recipe_hub.sql` - deterministic demo data for development and integration

During startup, the script:

1. Starts PostgreSQL if needed.
2. Ensures the application database and user exist.
3. Grants schema permissions.
4. Executes the Recipe Hub schema bootstrap.
5. Executes the Recipe Hub seed bootstrap.

This approach keeps the current container startup pattern intact while making the application schema reproducible for CI and local recovery.

## Schema overview

Core entities included:

- `app_users`
- `recipes`
- `recipe_ingredients`
- `recipe_steps`
- `recipe_images`
- `categories`
- `tags`
- `recipe_categories`
- `recipe_tags`
- `favorites`
- `shopping_lists`
- `shopping_list_items`
- `shopping_list_recipe_sources`
- `moderation_actions`
- `moderation_flags`
- `recipe_reviews`

Nice-to-have support included:

- `meal_plans`
- `meal_plan_entries`
- `recipe_nutrition`

## Design notes

- UUID primary keys are used throughout.
- Many-to-many joins are normalized for categories, tags, favorites, and shopping list recipe sources.
- Moderation uses both a current recipe state and an audit trail table.
- Nutrition and meal planning are optional but included to support later backend features without requiring schema redesign.
- Search support is prepared through a `tsvector` column and trigger on recipes.
- Rating aggregates are maintained automatically from `recipe_reviews`.

## Seed data strategy

The seed file is intended for development/demo environments and is safe to re-run:

- Uses `ON CONFLICT` upserts where appropriate.
- Rebuilds nested seed content such as recipe ingredients and steps deterministically.
- Creates demo users, categories, tags, recipes, favorites, shopping lists, moderation samples, meal plans, and nutrition rows.

## Connection

The active connection string is written to:

- `db_connection.txt`

Typical usage:

```bash
psql postgresql://appuser:dbuser123@localhost:5000/myapp
```

## Notes for future backend integration

The backend should treat these tables as the authoritative data model for:

- authentication/account ownership
- recipe CRUD and publishing
- browse/search and filtering
- favorites
- shopping list generation
- moderation workflows
- meal planning and nutrition display
