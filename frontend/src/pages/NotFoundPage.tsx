import { Link } from 'react-router'

export function NotFoundPage() {
  return (
    <div className="flex flex-col items-center justify-center py-20">
      <h1 className="text-6xl font-bold text-rex-text-secondary dark:text-rex-text-secondary-dark mb-4">404</h1>
      <p className="text-lg text-rex-text-secondary dark:text-rex-text-secondary-dark mb-8">Page not found</p>
      <Link to="/" className="text-rex-primary hover:underline">
        Back to home
      </Link>
    </div>
  )
}
