import React from "react";
import { Link, Outlet, useLocation } from "react-router-dom";
import { LayoutDashboard, ListTodo, FolderOpen, Briefcase } from "lucide-react";

const DashboardLayout: React.FC = () => {
  const location = useLocation();
  const currentPath = location.pathname;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="flex">
        {/* Sidebar */}
        <div className="w-64 bg-white shadow-md min-h-screen p-4">
          <div className="text-xl font-bold text-primary mb-6 flex items-center gap-2">
            <LayoutDashboard className="h-6 w-6" />
            Dashboard
          </div>

          <nav className="space-y-2">
            <Link
              to="/dashboard"
              className={`flex items-center gap-2 p-2 rounded-md w-full ${
                currentPath === "/dashboard"
                  ? "bg-primary text-primary-foreground"
                  : "hover:bg-muted"
              }`}
            >
              <ListTodo className="h-5 w-5" />
              Blog Posts
            </Link>
            <Link
              to="/dashboard/projects"
              className={`flex items-center gap-2 p-2 rounded-md w-full ${
                currentPath === "/dashboard/projects"
                  ? "bg-primary text-primary-foreground"
                  : "hover:bg-muted"
              }`}
            >
              <FolderOpen className="h-5 w-5" />
              Projects
            </Link>
            <Link
              to="/dashboard/academic"
              className={`flex items-center gap-2 p-2 rounded-md w-full ${
                currentPath === "/dashboard/academic"
                  ? "bg-primary text-primary-foreground"
                  : "hover:bg-muted"
              }`}
            >
              <ListTodo className="h-5 w-5" />
              Academic Posts
            </Link>
            <Link
              to="/dashboard/experience"
              className={`flex items-center gap-2 p-2 rounded-md w-full ${
                currentPath === "/dashboard/experience"
                  ? "bg-primary text-primary-foreground"
                  : "hover:bg-muted"
              }`}
            >
              <Briefcase className="h-5 w-5" />
              Experience
            </Link>
          </nav>
        </div>

        {/* Main Content */}
        <div className="flex-1 p-8">
          <Outlet />
        </div>
      </div>
    </div>
  );
};

export default DashboardLayout;
