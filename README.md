# Rhythm Roots - Learning Management System

A comprehensive learning management system built with SvelteKit 5, Supabase, and Tailwind CSS. This platform connects teachers and students in a modern, intuitive environment for music education.

## Features

### For Students
- Create free accounts and enroll in courses
- Access course materials and lessons
- Communicate with teachers via messages
- Track learning progress
- Calendar view of scheduled lessons

### For Teachers
- Create and manage courses and lessons
- Upload various media types (images, PDFs, videos, audio)
- Manage student enrollments
- Send messages to students
- Track earnings and analytics
- Custom URL for course discovery

### For Super Admins
- Monitor platform health and usage
- Manage teachers and students
- Track platform revenue
- Configure subscription pricing
- Send platform-wide communications

## Tech Stack

- **Frontend**: SvelteKit 5 with Svelte 5 runes
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Styling**: Tailwind CSS
- **Icons**: Lucide Svelte
- **Payments**: Stripe (planned)
- **TypeScript**: Full type safety

## Database Schema

The application uses a comprehensive PostgreSQL schema with the following main tables:

- `profiles` - User profiles with role-based access
- `courses` - Course information and metadata
- `lessons` - Individual lesson content
- `course_lessons` - Many-to-many relationship between courses and lessons
- `media` - File storage and media management
- `student_courses` - Student enrollments and payments
- `notes` - Messaging system between teachers and students
- `payments` - Payment tracking and revenue management
- `platform_settings` - System configuration

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd rhythmroots
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up Supabase**
   - Create a new project at [supabase.com](https://supabase.com)
   - Go to Settings → API to get your credentials
   - Create a `.env` file in the root directory:
   ```env
   PUBLIC_SUPABASE_URL=your_supabase_project_url
   PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   ENCRYPTION_KEY=your_encryption_key
   ```

4. **Set up the database**
   - Copy the contents of `database-schema.sql`
   - Paste it into the Supabase SQL Editor
   - Run the script to create all tables and relationships

5. **Start the development server**
   ```bash
   npm run dev
   ```

6. **Open your browser**
   Navigate to `http://localhost:5173`

## Project Structure

```
src/
├── lib/
│   ├── auth.ts              # Authentication utilities
│   ├── supabase.ts          # Supabase client configuration
│   ├── supabase-server.ts   # Server-side Supabase client
│   ├── db-utils.ts          # Database utility functions
│   ├── index.ts             # Central exports
│   └── components/          # Reusable UI components
├── routes/
│   ├── auth/                # Authentication pages
│   │   ├── login/
│   │   └── register/
│   ├── dashboard/           # Role-based dashboards
│   │   ├── student/
│   │   ├── teacher/
│   │   └── admin/
│   ├── courses/             # Course browsing
│   └── +layout.svelte       # Main layout
└── app.html                 # HTML template
```

## User Roles

### Student
- Default role for new registrations
- Can enroll in courses
- Access course materials
- Communicate with teachers

### Teacher
- Can create courses and lessons
- Manage student enrollments
- Upload media content
- Send messages to students
- View analytics and earnings

### Super Admin
- Platform-wide access
- Manage all users
- Configure system settings
- View platform analytics
- Must be manually assigned in database

## Subscription Plans

### Starter (Free)
- $2.50 per student per month
- 1 course with up to 100 lessons
- No messaging
- No reporting
- Lesson scheduling
- Image and PDF media only
- 500MB storage
- Auto-generated custom URL

### Freelance ($10/month)
- $1 per student per month
- Unlimited courses and lessons
- 100 messages per month
- 1GB storage
- All media types
- Advanced reporting
- Editable custom URL

### Business ($20/month)
- $0.50 per student per month
- Unlimited courses and lessons
- Unlimited messaging
- 10GB storage
- All media types
- Advanced reporting
- Custom domain support

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run check` - Run type checking
- `npm run lint` - Run ESLint
- `npm run format` - Format code with Prettier

### Code Style

- Use Svelte 5 runes (`$state`, `$effect`, etc.)
- Follow TypeScript best practices
- Use Tailwind CSS for styling
- Prefer composition over inheritance
- Write descriptive component and function names

## Deployment

The application is configured to work with various deployment platforms:

- **Vercel**: Use `@sveltejs/adapter-vercel`
- **Netlify**: Use `@sveltejs/adapter-netlify`
- **Node.js**: Use `@sveltejs/adapter-node`

Update the adapter in `svelte.config.js` based on your deployment target.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository or contact the development team.

---

**Note**: This is a development version. Some features like Stripe integration and email notifications are planned for future releases.
