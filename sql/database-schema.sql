-- Rhythm Roots Learning Management System Database Schema
-- Run this in your Supabase SQL Editor

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types
CREATE TYPE user_role AS ENUM ('student', 'teacher', 'super_admin');
CREATE TYPE subscription_plan AS ENUM ('starter', 'freelance', 'business');
CREATE TYPE lesson_status AS ENUM ('active', 'inactive', 'disabled');
CREATE TYPE media_type AS ENUM ('image', 'pdf', 'video_url', 'audio');
CREATE TYPE note_scope AS ENUM ('course', 'lesson', 'student');

-- Profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'student',
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    address JSONB, -- Store address as JSON for flexibility
    custom_fields JSONB DEFAULT '{}', -- Teacher-defined custom fields
    account_slug TEXT UNIQUE, -- For custom URLs
    subscription_plan subscription_plan DEFAULT 'starter',
    subscription_active BOOLEAN DEFAULT false,
    stripe_customer_id TEXT,
    stripe_account_id TEXT, -- For teachers' own Stripe accounts
    media_storage_used BIGINT DEFAULT 0, -- In bytes
    messages_sent_this_month INTEGER DEFAULT 0,
    subscription_start_date TIMESTAMP WITH TIME ZONE,
    subscription_end_date TIMESTAMP WITH TIME ZONE,
    is_suspended BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Courses table
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT, -- WYSIWYG content
    image_url TEXT,
    price DECIMAL(10,2) DEFAULT 0,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Lessons table
CREATE TABLE lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT, -- WYSIWYG content
    image_url TEXT,
    content_blocks JSONB DEFAULT '[]', -- Array of WYSIWYG content blocks
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Course-Lesson relationships (many-to-many)
CREATE TABLE course_lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    status lesson_status DEFAULT 'inactive',
    scheduled_date DATE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(course_id, lesson_id)
);

-- Media table
CREATE TABLE media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT, -- WYSIWYG content
    file_url TEXT, -- For uploaded files
    video_url TEXT, -- For video embeds
    media_type media_type NOT NULL,
    file_size BIGINT, -- In bytes
    mime_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student-Course enrollments
CREATE TABLE student_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    payment_status TEXT DEFAULT 'pending', -- pending, paid, failed, refunded
    stripe_subscription_id TEXT,
    stripe_payment_intent_id TEXT,
    amount_paid DECIMAL(10,2),
    payment_date TIMESTAMP WITH TIME ZONE,
    UNIQUE(student_id, course_id)
);

-- Notes/Messages table
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    message TEXT NOT NULL, -- WYSIWYG content
    scope note_scope NOT NULL,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE CASCADE,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    email_sent BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Note replies
CREATE TABLE note_replies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    note_id UUID NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_from_email BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student-specific lesson content
CREATE TABLE student_lesson_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    media_id UUID REFERENCES media(id) ON DELETE CASCADE,
    content TEXT, -- WYSIWYG content specific to this student
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, lesson_id, media_id)
);

-- Platform settings (for Super Admin)
CREATE TABLE platform_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT NOT NULL UNIQUE,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payment records
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'usd',
    stripe_payment_intent_id TEXT,
    stripe_charge_id TEXT,
    platform_fee DECIMAL(10,2) DEFAULT 0,
    teacher_earnings DECIMAL(10,2) DEFAULT 0,
    status TEXT NOT NULL, -- pending, succeeded, failed, refunded
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_account_slug ON profiles(account_slug);
CREATE INDEX idx_courses_teacher_id ON courses(teacher_id);
CREATE INDEX idx_course_lessons_course_id ON course_lessons(course_id);
CREATE INDEX idx_course_lessons_lesson_id ON course_lessons(lesson_id);
CREATE INDEX idx_student_courses_student_id ON student_courses(student_id);
CREATE INDEX idx_student_courses_course_id ON student_courses(course_id);
CREATE INDEX idx_notes_teacher_id ON notes(teacher_id);
CREATE INDEX idx_notes_student_id ON notes(student_id);
CREATE INDEX idx_notes_course_id ON notes(course_id);
CREATE INDEX idx_media_teacher_id ON media(teacher_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE media ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_lesson_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Super admins can view all profiles" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'super_admin'
        )
    );

-- Courses policies
CREATE POLICY "Teachers can view their own courses" ON courses
    FOR SELECT USING (teacher_id = auth.uid());

CREATE POLICY "Students can view courses they're enrolled in" ON courses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM student_courses 
            WHERE course_id = courses.id AND student_id = auth.uid()
        )
    );

CREATE POLICY "Teachers can manage their own courses" ON courses
    FOR ALL USING (teacher_id = auth.uid());

-- Student courses policies
CREATE POLICY "Students can view their own enrollments" ON student_courses
    FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Teachers can view enrollments for their courses" ON student_courses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM courses 
            WHERE id = student_courses.course_id AND teacher_id = auth.uid()
        )
    );

-- Insert initial platform settings
INSERT INTO platform_settings (key, value, description) VALUES
('subscription_pricing', '{"starter": {"base_price": 0, "per_student": 2.50}, "freelance": {"base_price": 10, "per_student": 1.00}, "business": {"base_price": 20, "per_student": 0.50}}', 'Subscription pricing tiers'),
('platform_fee_percentage', '0.05', 'Platform fee percentage (5%)'),
('stripe_platform_account_id', '""', 'Platform Stripe account ID'),
('mailchimp_api_key', '""', 'Mailchimp API key for email marketing'),
('max_storage_starter', '536870912', 'Max storage for starter plan (500MB)'),
('max_storage_freelance', '1073741824', 'Max storage for freelance plan (1GB)'),
('max_storage_business', '10737418240', 'Max storage for business plan (10GB)');

-- Create a function to generate account slugs
CREATE OR REPLACE FUNCTION generate_account_slug()
RETURNS TEXT AS $$
DECLARE
    slug TEXT;
    counter INTEGER := 0;
BEGIN
    LOOP
        slug := LPAD(floor(random() * 1000000)::TEXT, 6, '0');
        
        -- Check if slug already exists
        IF NOT EXISTS (SELECT 1 FROM profiles WHERE account_slug = slug) THEN
            RETURN slug;
        END IF;
        
        counter := counter + 1;
        IF counter > 100 THEN
            -- Fallback to UUID if we can't find a unique number
            slug := 'user-' || substr(uuid_generate_v4()::TEXT, 1, 8);
            RETURN slug;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create a function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, first_name, last_name, email, role, account_slug)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'student')::user_role,
        generate_account_slug()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
