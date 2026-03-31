BEGIN;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TYPE moderation_status AS ENUM ('draft', 'pending_review', 'approved', 'rejected', 'archived');
CREATE TYPE shopping_list_status AS ENUM ('active', 'completed', 'archived');
CREATE TYPE shopping_item_status AS ENUM ('pending', 'purchased', 'removed');
CREATE TYPE meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');
CREATE TYPE recipe_visibility AS ENUM ('private', 'unlisted', 'public');

CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(120),
    bio TEXT,
    avatar_url TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_app_users_role CHECK (role IN ('user', 'admin', 'moderator'))
);

CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    parent_category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(220) NOT NULL UNIQUE,
    description TEXT,
    hero_image_url TEXT,
    prep_time_minutes INTEGER NOT NULL DEFAULT 0,
    cook_time_minutes INTEGER NOT NULL DEFAULT 0,
    total_time_minutes INTEGER GENERATED ALWAYS AS (prep_time_minutes + cook_time_minutes) STORED,
    servings INTEGER NOT NULL DEFAULT 1,
    difficulty VARCHAR(20) NOT NULL DEFAULT 'easy',
    visibility recipe_visibility NOT NULL DEFAULT 'public',
    moderation_state moderation_status NOT NULL DEFAULT 'pending_review',
    moderation_notes TEXT,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMPTZ,
    average_rating NUMERIC(3,2) NOT NULL DEFAULT 0,
    rating_count INTEGER NOT NULL DEFAULT 0,
    search_vector tsvector,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_recipes_difficulty CHECK (difficulty IN ('easy', 'medium', 'hard')),
    CONSTRAINT chk_recipes_prep_time CHECK (prep_time_minutes >= 0),
    CONSTRAINT chk_recipes_cook_time CHECK (cook_time_minutes >= 0),
    CONSTRAINT chk_recipes_servings CHECK (servings > 0)
);

CREATE TABLE IF NOT EXISTS recipe_categories (
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (recipe_id, category_id)
);

CREATE TABLE IF NOT EXISTS recipe_tags (
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (recipe_id, tag_id)
);

CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    sort_order INTEGER NOT NULL,
    name VARCHAR(200) NOT NULL,
    quantity NUMERIC(10,2),
    unit VARCHAR(50),
    preparation_note VARCHAR(255),
    optional BOOLEAN NOT NULL DEFAULT FALSE,
    pantry_item BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_recipe_ingredients_order UNIQUE (recipe_id, sort_order),
    CONSTRAINT chk_recipe_ingredients_quantity CHECK (quantity IS NULL OR quantity >= 0)
);

CREATE TABLE IF NOT EXISTS recipe_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    instruction TEXT NOT NULL,
    image_url TEXT,
    timer_seconds INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_recipe_steps_number UNIQUE (recipe_id, step_number),
    CONSTRAINT chk_recipe_steps_number CHECK (step_number > 0),
    CONSTRAINT chk_recipe_steps_timer CHECK (timer_seconds IS NULL OR timer_seconds >= 0)
);

CREATE TABLE IF NOT EXISTS recipe_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    alt_text VARCHAR(255),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS recipe_nutrition (
    recipe_id UUID PRIMARY KEY REFERENCES recipes(id) ON DELETE CASCADE,
    calories INTEGER,
    protein_g NUMERIC(8,2),
    carbs_g NUMERIC(8,2),
    fat_g NUMERIC(8,2),
    fiber_g NUMERIC(8,2),
    sugar_g NUMERIC(8,2),
    sodium_mg NUMERIC(10,2),
    nutrition_source VARCHAR(100),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_recipe_nutrition_values CHECK (
        (calories IS NULL OR calories >= 0) AND
        (protein_g IS NULL OR protein_g >= 0) AND
        (carbs_g IS NULL OR carbs_g >= 0) AND
        (fat_g IS NULL OR fat_g >= 0) AND
        (fiber_g IS NULL OR fiber_g >= 0) AND
        (sugar_g IS NULL OR sugar_g >= 0) AND
        (sodium_mg IS NULL OR sodium_mg >= 0)
    )
);

CREATE TABLE IF NOT EXISTS favorites (
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, recipe_id)
);

CREATE TABLE IF NOT EXISTS shopping_lists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    status shopping_list_status NOT NULL DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shopping_list_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
    source_recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
    ingredient_name VARCHAR(200) NOT NULL,
    quantity NUMERIC(10,2),
    unit VARCHAR(50),
    item_status shopping_item_status NOT NULL DEFAULT 'pending',
    sort_order INTEGER NOT NULL DEFAULT 0,
    notes VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_shopping_list_items_quantity CHECK (quantity IS NULL OR quantity >= 0)
);

CREATE TABLE IF NOT EXISTS shopping_list_recipe_sources (
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    servings_multiplier NUMERIC(8,2) NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (shopping_list_id, recipe_id),
    CONSTRAINT chk_shopping_list_recipe_sources_multiplier CHECK (servings_multiplier > 0)
);

CREATE TABLE IF NOT EXISTS meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    week_start_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS meal_plan_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_plan_id UUID NOT NULL REFERENCES meal_plans(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    planned_for_date DATE NOT NULL,
    meal_slot meal_type NOT NULL,
    servings INTEGER NOT NULL DEFAULT 1,
    notes VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_meal_plan_entries UNIQUE (meal_plan_id, planned_for_date, meal_slot),
    CONSTRAINT chk_meal_plan_entries_servings CHECK (servings > 0)
);

CREATE TABLE IF NOT EXISTS recipe_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL,
    review_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_recipe_reviews_user UNIQUE (recipe_id, user_id),
    CONSTRAINT chk_recipe_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE IF NOT EXISTS moderation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    moderator_id UUID NOT NULL REFERENCES app_users(id) ON DELETE RESTRICT,
    action moderation_status NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS moderation_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    reported_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
    reason VARCHAR(100) NOT NULL,
    details TEXT,
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_recipes_author_id ON recipes(author_id);
CREATE INDEX IF NOT EXISTS idx_recipes_visibility_state ON recipes(visibility, moderation_state, is_published);
CREATE INDEX IF NOT EXISTS idx_recipes_search_vector ON recipes USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_steps_recipe_id ON recipe_steps(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_images_recipe_id ON recipe_images(recipe_id);
CREATE INDEX IF NOT EXISTS idx_favorites_recipe_id ON favorites(recipe_id);
CREATE INDEX IF NOT EXISTS idx_shopping_lists_user_id ON shopping_lists(user_id);
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_list_id ON shopping_list_items(shopping_list_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_id ON meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plan_entries_plan_date ON meal_plan_entries(meal_plan_id, planned_for_date);
CREATE INDEX IF NOT EXISTS idx_recipe_reviews_recipe_id ON recipe_reviews(recipe_id);
CREATE INDEX IF NOT EXISTS idx_moderation_flags_recipe_id ON moderation_flags(recipe_id);
CREATE INDEX IF NOT EXISTS idx_moderation_actions_recipe_id ON moderation_actions(recipe_id);

CREATE OR REPLACE FUNCTION update_recipe_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_recipes_search_vector ON recipes;
CREATE TRIGGER trg_recipes_search_vector
BEFORE INSERT OR UPDATE OF title, description
ON recipes
FOR EACH ROW
EXECUTE FUNCTION update_recipe_search_vector();

DROP TRIGGER IF EXISTS trg_app_users_updated_at ON app_users;
CREATE TRIGGER trg_app_users_updated_at
BEFORE UPDATE ON app_users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_recipes_updated_at ON recipes;
CREATE TRIGGER trg_recipes_updated_at
BEFORE UPDATE ON recipes
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_recipe_nutrition_updated_at ON recipe_nutrition;
CREATE TRIGGER trg_recipe_nutrition_updated_at
BEFORE UPDATE ON recipe_nutrition
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_shopping_lists_updated_at ON shopping_lists;
CREATE TRIGGER trg_shopping_lists_updated_at
BEFORE UPDATE ON shopping_lists
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_shopping_list_items_updated_at ON shopping_list_items;
CREATE TRIGGER trg_shopping_list_items_updated_at
BEFORE UPDATE ON shopping_list_items
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_meal_plans_updated_at ON meal_plans;
CREATE TRIGGER trg_meal_plans_updated_at
BEFORE UPDATE ON meal_plans
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_recipe_reviews_updated_at ON recipe_reviews;
CREATE TRIGGER trg_recipe_reviews_updated_at
BEFORE UPDATE ON recipe_reviews
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE FUNCTION refresh_recipe_rating_summary(target_recipe_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE recipes
    SET
        average_rating = COALESCE((
            SELECT ROUND(AVG(rating)::numeric, 2)
            FROM recipe_reviews
            WHERE recipe_id = target_recipe_id
        ), 0),
        rating_count = (
            SELECT COUNT(*)
            FROM recipe_reviews
            WHERE recipe_id = target_recipe_id
        )
    WHERE id = target_recipe_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sync_recipe_rating_summary()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM refresh_recipe_rating_summary(OLD.recipe_id);
        RETURN OLD;
    END IF;

    PERFORM refresh_recipe_rating_summary(NEW.recipe_id);

    IF TG_OP = 'UPDATE' AND OLD.recipe_id <> NEW.recipe_id THEN
        PERFORM refresh_recipe_rating_summary(OLD.recipe_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_recipe_reviews_rating_summary ON recipe_reviews;
CREATE TRIGGER trg_recipe_reviews_rating_summary
AFTER INSERT OR UPDATE OR DELETE ON recipe_reviews
FOR EACH ROW
EXECUTE FUNCTION sync_recipe_rating_summary();

CREATE OR REPLACE VIEW recipe_public_summary AS
SELECT
    r.id,
    r.slug,
    r.title,
    r.description,
    r.hero_image_url,
    r.prep_time_minutes,
    r.cook_time_minutes,
    r.total_time_minutes,
    r.servings,
    r.difficulty,
    r.average_rating,
    r.rating_count,
    r.created_at,
    u.username AS author_username,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT c.name), NULL) AS categories,
    ARRAY_REMOVE(ARRAY_AGG(DISTINCT t.name), NULL) AS tags
FROM recipes r
JOIN app_users u ON u.id = r.author_id
LEFT JOIN recipe_categories rc ON rc.recipe_id = r.id
LEFT JOIN categories c ON c.id = rc.category_id
LEFT JOIN recipe_tags rt ON rt.recipe_id = r.id
LEFT JOIN tags t ON t.id = rt.tag_id
WHERE r.visibility = 'public'
  AND r.is_published = TRUE
  AND r.moderation_state = 'approved'
GROUP BY r.id, u.username;

COMMIT;
