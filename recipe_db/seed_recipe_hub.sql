BEGIN;

INSERT INTO app_users (email, username, password_hash, full_name, bio, role, is_active, is_verified)
VALUES
    ('admin@recipehub.dev', 'adminchef', 'demo-hash-admin', 'Recipe Hub Admin', 'Platform administrator and content reviewer.', 'admin', TRUE, TRUE),
    ('mia@recipehub.dev', 'mia', 'demo-hash-mia', 'Mia Summers', 'Home cook sharing bright weekday recipes.', 'user', TRUE, TRUE),
    ('leo@recipehub.dev', 'leo', 'demo-hash-leo', 'Leo Carter', 'Weekend meal prep enthusiast.', 'moderator', TRUE, TRUE)
ON CONFLICT (email) DO UPDATE
SET
    username = EXCLUDED.username,
    full_name = EXCLUDED.full_name,
    bio = EXCLUDED.bio,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    is_verified = EXCLUDED.is_verified;

INSERT INTO categories (slug, name, description, display_order)
VALUES
    ('breakfast', 'Breakfast', 'Morning recipes and brunch ideas.', 1),
    ('dinner', 'Dinner', 'Hearty mains and evening meals.', 2),
    ('meal-prep', 'Meal Prep', 'Recipes designed for batching ahead.', 3),
    ('vegetarian', 'Vegetarian', 'Plant-forward recipes.', 4),
    ('dessert', 'Dessert', 'Sweet treats and bakes.', 5)
ON CONFLICT (slug) DO UPDATE
SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    display_order = EXCLUDED.display_order;

INSERT INTO tags (slug, name, description)
VALUES
    ('quick', 'Quick', 'Ready in under 30 minutes.'),
    ('family-friendly', 'Family Friendly', 'Crowd-pleasing and easy to share.'),
    ('high-protein', 'High Protein', 'Protein-forward meals.'),
    ('gluten-free', 'Gluten Free', 'Recipes without gluten ingredients.'),
    ('retro-favorite', 'Retro Favorite', 'Comfort dishes with nostalgic flair.')
ON CONFLICT (slug) DO UPDATE
SET
    name = EXCLUDED.name,
    description = EXCLUDED.description;

INSERT INTO recipes (
    author_id,
    title,
    slug,
    description,
    hero_image_url,
    prep_time_minutes,
    cook_time_minutes,
    servings,
    difficulty,
    visibility,
    moderation_state,
    moderation_notes,
    is_published,
    published_at
)
SELECT
    u.id,
    'Citrus Sunrise Oats',
    'citrus-sunrise-oats',
    'Creamy overnight oats with orange zest, yogurt, and berries.',
    'https://images.unsplash.com/photo-1517673400267-0251440c45dc',
    10,
    0,
    2,
    'easy',
    'public',
    'approved',
    'Approved as demo breakfast content.',
    TRUE,
    CURRENT_TIMESTAMP
FROM app_users u
WHERE u.email = 'mia@recipehub.dev'
ON CONFLICT (slug) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    hero_image_url = EXCLUDED.hero_image_url,
    prep_time_minutes = EXCLUDED.prep_time_minutes,
    cook_time_minutes = EXCLUDED.cook_time_minutes,
    servings = EXCLUDED.servings,
    difficulty = EXCLUDED.difficulty,
    visibility = EXCLUDED.visibility,
    moderation_state = EXCLUDED.moderation_state,
    moderation_notes = EXCLUDED.moderation_notes,
    is_published = EXCLUDED.is_published,
    published_at = EXCLUDED.published_at;

INSERT INTO recipes (
    author_id,
    title,
    slug,
    description,
    hero_image_url,
    prep_time_minutes,
    cook_time_minutes,
    servings,
    difficulty,
    visibility,
    moderation_state,
    moderation_notes,
    is_published,
    published_at
)
SELECT
    u.id,
    'Weeknight Tomato Basil Pasta',
    'weeknight-tomato-basil-pasta',
    'A pantry-friendly pasta with rich tomato sauce, basil, and parmesan.',
    'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9',
    15,
    20,
    4,
    'easy',
    'public',
    'approved',
    'Approved as demo dinner content.',
    TRUE,
    CURRENT_TIMESTAMP
FROM app_users u
WHERE u.email = 'leo@recipehub.dev'
ON CONFLICT (slug) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    hero_image_url = EXCLUDED.hero_image_url,
    prep_time_minutes = EXCLUDED.prep_time_minutes,
    cook_time_minutes = EXCLUDED.cook_time_minutes,
    servings = EXCLUDED.servings,
    difficulty = EXCLUDED.difficulty,
    visibility = EXCLUDED.visibility,
    moderation_state = EXCLUDED.moderation_state,
    moderation_notes = EXCLUDED.moderation_notes,
    is_published = EXCLUDED.is_published,
    published_at = EXCLUDED.published_at;

INSERT INTO recipes (
    author_id,
    title,
    slug,
    description,
    hero_image_url,
    prep_time_minutes,
    cook_time_minutes,
    servings,
    difficulty,
    visibility,
    moderation_state,
    moderation_notes,
    is_published,
    published_at
)
SELECT
    u.id,
    'Hidden Veggie Mac Bake',
    'hidden-veggie-mac-bake',
    'Comforting baked pasta packed with blended vegetables for picky eaters.',
    'https://images.unsplash.com/photo-1543339494-b4cd4f7ba686',
    25,
    30,
    6,
    'medium',
    'public',
    'pending_review',
    'Awaiting moderator review for launch demo.',
    FALSE,
    NULL
FROM app_users u
WHERE u.email = 'mia@recipehub.dev'
ON CONFLICT (slug) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    hero_image_url = EXCLUDED.hero_image_url,
    prep_time_minutes = EXCLUDED.prep_time_minutes,
    cook_time_minutes = EXCLUDED.cook_time_minutes,
    servings = EXCLUDED.servings,
    difficulty = EXCLUDED.difficulty,
    visibility = EXCLUDED.visibility,
    moderation_state = EXCLUDED.moderation_state,
    moderation_notes = EXCLUDED.moderation_notes,
    is_published = EXCLUDED.is_published,
    published_at = EXCLUDED.published_at;

INSERT INTO recipe_categories (recipe_id, category_id)
SELECT r.id, c.id
FROM recipes r
JOIN categories c ON c.slug IN ('breakfast', 'vegetarian')
WHERE r.slug = 'citrus-sunrise-oats'
ON CONFLICT DO NOTHING;

INSERT INTO recipe_categories (recipe_id, category_id)
SELECT r.id, c.id
FROM recipes r
JOIN categories c ON c.slug IN ('dinner', 'meal-prep')
WHERE r.slug = 'weeknight-tomato-basil-pasta'
ON CONFLICT DO NOTHING;

INSERT INTO recipe_categories (recipe_id, category_id)
SELECT r.id, c.id
FROM recipes r
JOIN categories c ON c.slug IN ('dinner', 'family-meals')
WHERE FALSE
ON CONFLICT DO NOTHING;

INSERT INTO recipe_categories (recipe_id, category_id)
SELECT r.id, c.id
FROM recipes r
JOIN categories c ON c.slug IN ('dinner')
WHERE r.slug = 'hidden-veggie-mac-bake'
ON CONFLICT DO NOTHING;

INSERT INTO recipe_tags (recipe_id, tag_id)
SELECT r.id, t.id
FROM recipes r
JOIN tags t ON t.slug IN ('quick', 'family-friendly')
WHERE r.slug = 'citrus-sunrise-oats'
ON CONFLICT DO NOTHING;

INSERT INTO recipe_tags (recipe_id, tag_id)
SELECT r.id, t.id
FROM recipes r
JOIN tags t ON t.slug IN ('family-friendly', 'retro-favorite')
WHERE r.slug = 'weeknight-tomato-basil-pasta'
ON CONFLICT DO NOTHING;

INSERT INTO recipe_tags (recipe_id, tag_id)
SELECT r.id, t.id
FROM recipes r
JOIN tags t ON t.slug IN ('family-friendly', 'high-protein')
WHERE r.slug = 'hidden-veggie-mac-bake'
ON CONFLICT DO NOTHING;

DELETE FROM recipe_ingredients
WHERE recipe_id IN (
    SELECT id FROM recipes
    WHERE slug IN (
        'citrus-sunrise-oats',
        'weeknight-tomato-basil-pasta',
        'hidden-veggie-mac-bake'
    )
);

INSERT INTO recipe_ingredients (recipe_id, sort_order, name, quantity, unit, preparation_note, optional, pantry_item)
SELECT r.id, v.sort_order, v.name, v.quantity, v.unit, v.preparation_note, v.optional, v.pantry_item
FROM recipes r
JOIN (
    VALUES
        ('citrus-sunrise-oats', 1, 'Rolled oats', 1.00, 'cup', NULL, FALSE, TRUE),
        ('citrus-sunrise-oats', 2, 'Greek yogurt', 0.75, 'cup', NULL, FALSE, FALSE),
        ('citrus-sunrise-oats', 3, 'Milk', 0.75, 'cup', 'Any preferred milk', FALSE, FALSE),
        ('citrus-sunrise-oats', 4, 'Orange zest', 1.00, 'tbsp', 'Freshly grated', FALSE, FALSE),
        ('citrus-sunrise-oats', 5, 'Honey', 1.00, 'tbsp', NULL, TRUE, TRUE),
        ('citrus-sunrise-oats', 6, 'Mixed berries', 0.50, 'cup', 'For serving', FALSE, FALSE),

        ('weeknight-tomato-basil-pasta', 1, 'Pasta', 12.00, 'oz', 'Any short pasta shape', FALSE, TRUE),
        ('weeknight-tomato-basil-pasta', 2, 'Olive oil', 2.00, 'tbsp', NULL, FALSE, TRUE),
        ('weeknight-tomato-basil-pasta', 3, 'Garlic cloves', 3.00, NULL, 'Minced', FALSE, FALSE),
        ('weeknight-tomato-basil-pasta', 4, 'Crushed tomatoes', 28.00, 'oz', 'One can', FALSE, TRUE),
        ('weeknight-tomato-basil-pasta', 5, 'Fresh basil', 0.50, 'cup', 'Torn', FALSE, FALSE),
        ('weeknight-tomato-basil-pasta', 6, 'Parmesan', 0.50, 'cup', 'Grated', TRUE, FALSE),

        ('hidden-veggie-mac-bake', 1, 'Elbow macaroni', 16.00, 'oz', NULL, FALSE, TRUE),
        ('hidden-veggie-mac-bake', 2, 'Cauliflower florets', 2.00, 'cups', 'Steamed', FALSE, FALSE),
        ('hidden-veggie-mac-bake', 3, 'Carrot', 1.00, NULL, 'Chopped', FALSE, FALSE),
        ('hidden-veggie-mac-bake', 4, 'Milk', 2.00, 'cups', NULL, FALSE, FALSE),
        ('hidden-veggie-mac-bake', 5, 'Cheddar cheese', 2.00, 'cups', 'Shredded', FALSE, FALSE),
        ('hidden-veggie-mac-bake', 6, 'Breadcrumbs', 0.50, 'cup', 'For topping', TRUE, TRUE)
) AS v(recipe_slug, sort_order, name, quantity, unit, preparation_note, optional, pantry_item)
    ON r.slug = v.recipe_slug;

DELETE FROM recipe_steps
WHERE recipe_id IN (
    SELECT id FROM recipes
    WHERE slug IN (
        'citrus-sunrise-oats',
        'weeknight-tomato-basil-pasta',
        'hidden-veggie-mac-bake'
    )
);

INSERT INTO recipe_steps (recipe_id, step_number, instruction, timer_seconds)
SELECT r.id, v.step_number, v.instruction, v.timer_seconds
FROM recipes r
JOIN (
    VALUES
        ('citrus-sunrise-oats', 1, 'Whisk oats, yogurt, milk, orange zest, and honey in a jar.', NULL),
        ('citrus-sunrise-oats', 2, 'Cover and chill overnight or at least 4 hours.', 14400),
        ('citrus-sunrise-oats', 3, 'Top with berries before serving.', NULL),

        ('weeknight-tomato-basil-pasta', 1, 'Cook pasta in salted water until al dente.', 720),
        ('weeknight-tomato-basil-pasta', 2, 'Saute garlic in olive oil until fragrant.', 120),
        ('weeknight-tomato-basil-pasta', 3, 'Add tomatoes and simmer until slightly thickened.', 900),
        ('weeknight-tomato-basil-pasta', 4, 'Toss pasta with sauce, basil, and parmesan.', NULL),

        ('hidden-veggie-mac-bake', 1, 'Cook macaroni just under package directions.', 600),
        ('hidden-veggie-mac-bake', 2, 'Blend cauliflower, carrot, and milk until smooth.', 180),
        ('hidden-veggie-mac-bake', 3, 'Stir puree into macaroni with cheddar cheese.', 300),
        ('hidden-veggie-mac-bake', 4, 'Top with breadcrumbs and bake until golden.', 1500)
) AS v(recipe_slug, step_number, instruction, timer_seconds)
    ON r.slug = v.recipe_slug;

DELETE FROM recipe_images
WHERE recipe_id IN (
    SELECT id FROM recipes
    WHERE slug IN (
        'citrus-sunrise-oats',
        'weeknight-tomato-basil-pasta',
        'hidden-veggie-mac-bake'
    )
);

INSERT INTO recipe_images (recipe_id, image_url, alt_text, is_primary, sort_order)
SELECT r.id, r.hero_image_url, r.title || ' hero image', TRUE, 0
FROM recipes r
WHERE r.slug IN (
    'citrus-sunrise-oats',
    'weeknight-tomato-basil-pasta',
    'hidden-veggie-mac-bake'
);

INSERT INTO recipe_nutrition (recipe_id, calories, protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg, nutrition_source)
SELECT r.id, v.calories, v.protein_g, v.carbs_g, v.fat_g, v.fiber_g, v.sugar_g, v.sodium_mg, v.nutrition_source
FROM recipes r
JOIN (
    VALUES
        ('citrus-sunrise-oats', 320, 18.0, 42.0, 9.0, 6.0, 14.0, 120.0, 'seed-data'),
        ('weeknight-tomato-basil-pasta', 480, 16.0, 62.0, 17.0, 5.0, 8.0, 640.0, 'seed-data'),
        ('hidden-veggie-mac-bake', 510, 22.0, 49.0, 24.0, 4.0, 7.0, 710.0, 'seed-data')
) AS v(recipe_slug, calories, protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg, nutrition_source)
    ON r.slug = v.recipe_slug
ON CONFLICT (recipe_id) DO UPDATE
SET
    calories = EXCLUDED.calories,
    protein_g = EXCLUDED.protein_g,
    carbs_g = EXCLUDED.carbs_g,
    fat_g = EXCLUDED.fat_g,
    fiber_g = EXCLUDED.fiber_g,
    sugar_g = EXCLUDED.sugar_g,
    sodium_mg = EXCLUDED.sodium_mg,
    nutrition_source = EXCLUDED.nutrition_source;

INSERT INTO favorites (user_id, recipe_id)
SELECT u.id, r.id
FROM app_users u
JOIN recipes r ON r.slug IN ('citrus-sunrise-oats', 'weeknight-tomato-basil-pasta')
WHERE u.email = 'leo@recipehub.dev'
ON CONFLICT DO NOTHING;

INSERT INTO shopping_lists (user_id, name, status, notes)
SELECT u.id, 'Weekend Prep List', 'active', 'Generated from selected launch recipes.'
FROM app_users u
WHERE u.email = 'leo@recipehub.dev'
ON CONFLICT DO NOTHING;

INSERT INTO shopping_list_recipe_sources (shopping_list_id, recipe_id, servings_multiplier)
SELECT sl.id, r.id, 1.00
FROM shopping_lists sl
JOIN app_users u ON u.id = sl.user_id
JOIN recipes r ON r.slug IN ('weeknight-tomato-basil-pasta', 'citrus-sunrise-oats')
WHERE u.email = 'leo@recipehub.dev'
  AND sl.name = 'Weekend Prep List'
ON CONFLICT DO NOTHING;

DELETE FROM shopping_list_items
WHERE shopping_list_id IN (
    SELECT sl.id
    FROM shopping_lists sl
    JOIN app_users u ON u.id = sl.user_id
    WHERE u.email = 'leo@recipehub.dev'
      AND sl.name = 'Weekend Prep List'
);

INSERT INTO shopping_list_items (shopping_list_id, source_recipe_id, ingredient_name, quantity, unit, item_status, sort_order, notes)
SELECT sl.id, r.id, v.ingredient_name, v.quantity, v.unit, v.item_status::shopping_item_status, v.sort_order, v.notes
FROM shopping_lists sl
JOIN app_users u ON u.id = sl.user_id
JOIN recipes r ON r.slug = v.recipe_slug
JOIN (
    VALUES
        ('weeknight-tomato-basil-pasta', 'Pasta', 12.00, 'oz', 'pending', 1, NULL),
        ('weeknight-tomato-basil-pasta', 'Crushed tomatoes', 28.00, 'oz', 'pending', 2, NULL),
        ('weeknight-tomato-basil-pasta', 'Fresh basil', 0.50, 'cup', 'pending', 3, 'Buy extra for garnish'),
        ('citrus-sunrise-oats', 'Rolled oats', 1.00, 'cup', 'purchased', 4, NULL),
        ('citrus-sunrise-oats', 'Mixed berries', 0.50, 'cup', 'pending', 5, NULL)
) AS v(recipe_slug, ingredient_name, quantity, unit, item_status, sort_order, notes)
    ON TRUE
WHERE u.email = 'leo@recipehub.dev'
  AND sl.name = 'Weekend Prep List';

INSERT INTO meal_plans (user_id, title, week_start_date, notes)
SELECT u.id, 'Launch Week Plan', CURRENT_DATE, 'Seeded sample meal plan for onboarding demos.'
FROM app_users u
WHERE u.email = 'mia@recipehub.dev'
ON CONFLICT DO NOTHING;

INSERT INTO meal_plan_entries (meal_plan_id, recipe_id, planned_for_date, meal_slot, servings, notes)
SELECT mp.id, r.id, v.planned_for_date, v.meal_slot::meal_type, v.servings, v.notes
FROM meal_plans mp
JOIN app_users u ON u.id = mp.user_id
JOIN (
    VALUES
        ('citrus-sunrise-oats', CURRENT_DATE, 'breakfast', 2, 'Prep the night before'),
        ('weeknight-tomato-basil-pasta', CURRENT_DATE + INTERVAL '1 day', 'dinner', 4, 'Add side salad')
) AS v(recipe_slug, planned_for_date, meal_slot, servings, notes)
    ON TRUE
JOIN recipes r ON r.slug = v.recipe_slug
WHERE u.email = 'mia@recipehub.dev'
  AND mp.title = 'Launch Week Plan'
ON CONFLICT DO NOTHING;

INSERT INTO recipe_reviews (recipe_id, user_id, rating, review_text)
SELECT r.id, u.id, 5, 'Bright, creamy, and perfect for busy mornings.'
FROM recipes r
JOIN app_users u ON u.email = 'leo@recipehub.dev'
WHERE r.slug = 'citrus-sunrise-oats'
ON CONFLICT (recipe_id, user_id) DO UPDATE
SET
    rating = EXCLUDED.rating,
    review_text = EXCLUDED.review_text;

INSERT INTO moderation_actions (recipe_id, moderator_id, action, notes)
SELECT r.id, u.id, 'approved', 'Approved during initial sample content review.'
FROM recipes r
JOIN app_users u ON u.email = 'admin@recipehub.dev'
WHERE r.slug IN ('citrus-sunrise-oats', 'weeknight-tomato-basil-pasta')
ON CONFLICT DO NOTHING;

INSERT INTO moderation_flags (recipe_id, reported_by, reason, details, resolved, resolved_at, resolved_by)
SELECT r.id, reporter.id, 'missing_details', 'Need a clearer bake temperature before publication.', FALSE, NULL, NULL
FROM recipes r
JOIN app_users reporter ON reporter.email = 'leo@recipehub.dev'
WHERE r.slug = 'hidden-veggie-mac-bake'
ON CONFLICT DO NOTHING;

COMMIT;
