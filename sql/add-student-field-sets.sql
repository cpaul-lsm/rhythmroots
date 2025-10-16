-- Custom field sets for students per teacher and course
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'custom_field_type') THEN
        CREATE TYPE custom_field_type AS ENUM ('text','number','boolean','date','select','multiselect');
    ELSE
        -- Ensure all values exist (idempotent)
        BEGIN
            ALTER TYPE custom_field_type ADD VALUE IF NOT EXISTS 'text';
            ALTER TYPE custom_field_type ADD VALUE IF NOT EXISTS 'number';
            ALTER TYPE custom_field_type ADD VALUE IF NOT EXISTS 'boolean';
            ALTER TYPE custom_field_type ADD VALUE IF NOT EXISTS 'date';
            ALTER TYPE custom_field_type ADD VALUE IF NOT EXISTS 'select';
            ALTER TYPE custom_field_type ADD VALUE IF NOT EXISTS 'multiselect';
        EXCEPTION
            WHEN duplicate_object THEN NULL;
        END;
    END IF;
END$$;

CREATE TABLE IF NOT EXISTS student_field_sets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    active boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS student_fields (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    field_set_id uuid NOT NULL REFERENCES student_field_sets(id) ON DELETE CASCADE,
    key text NOT NULL,
    label text NOT NULL,
    type custom_field_type NOT NULL,
    required boolean DEFAULT false,
    options jsonb,
    order_index int DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    UNIQUE(field_set_id, key)
);

CREATE TABLE IF NOT EXISTS course_field_sets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id uuid NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    field_set_id uuid NOT NULL REFERENCES student_field_sets(id) ON DELETE CASCADE,
    order_index int DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    UNIQUE(course_id, field_set_id)
);

CREATE TABLE IF NOT EXISTS student_field_values (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    course_id uuid NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    field_id uuid NOT NULL REFERENCES student_fields(id) ON DELETE CASCADE,
    value jsonb NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    UNIQUE(student_id, course_id, field_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_sfv_student_course ON student_field_values(student_id, course_id);
CREATE INDEX IF NOT EXISTS idx_cfs_course ON course_field_sets(course_id);

-- RLS
ALTER TABLE student_field_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_field_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_field_values ENABLE ROW LEVEL SECURITY;

-- Policies: teachers manage their own sets/fields
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'student_field_sets' AND policyname = 'Teacher manage own sets'
    ) THEN
        CREATE POLICY "Teacher manage own sets" ON student_field_sets
            FOR ALL USING (teacher_id = auth.uid()) WITH CHECK (teacher_id = auth.uid());
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'student_fields' AND policyname = 'Teacher manage fields in own sets'
    ) THEN
        CREATE POLICY "Teacher manage fields in own sets" ON student_fields
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM student_field_sets s
                    WHERE s.id = student_fields.field_set_id AND s.teacher_id = auth.uid()
                )
            ) WITH CHECK (
                EXISTS (
                    SELECT 1 FROM student_field_sets s
                    WHERE s.id = student_fields.field_set_id AND s.teacher_id = auth.uid()
                )
            );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'course_field_sets' AND policyname = 'Teacher manage course set mappings'
    ) THEN
        CREATE POLICY "Teacher manage course set mappings" ON course_field_sets
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM courses c
                    WHERE c.id = course_field_sets.course_id AND c.teacher_id = auth.uid()
                )
            ) WITH CHECK (
                EXISTS (
                    SELECT 1 FROM courses c
                    WHERE c.id = course_field_sets.course_id AND c.teacher_id = auth.uid()
                )
            );
    END IF;
END $$;

-- Values: teachers can upsert values for their courses; students may view their own
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'student_field_values' AND policyname = 'Teacher view/modify values for own courses'
    ) THEN
        CREATE POLICY "Teacher view/modify values for own courses" ON student_field_values
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM courses c
                    WHERE c.id = student_field_values.course_id AND c.teacher_id = auth.uid()
                )
            ) WITH CHECK (
                EXISTS (
                    SELECT 1 FROM courses c
                    WHERE c.id = student_field_values.course_id AND c.teacher_id = auth.uid()
                )
            );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'student_field_values' AND policyname = 'Student view own values'
    ) THEN
        CREATE POLICY "Student view own values" ON student_field_values
            FOR SELECT USING (student_id = auth.uid());
    END IF;
END $$;


