import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ThemeProvider } from "@/providers/ThemeProvider";
import Index from "./pages/Index";
import Projects from "./pages/Projects";
import Blog from "./pages/Blog";
import Academic from "./pages/Academic";
import Experience from "./pages/Experience";
import Contact from "./pages/Contact";
import NotFound from "./pages/NotFound";
import LoginPage from "./pages/Login";
// import DashboardPage from "./pages/DashboardPage";
import ForecastPage from "./pages/ForecastPage";
// import DashbroadProject from "./pages/DashbroadProject";
import DashboardLayout from "./components/DashboardLayout";
import BlogDashboard from "./pages/BlogDashboard";
import ProjectDashboard from "./pages/ProjectDashboard";
import AcademicDashboard from "./pages/AcademicDashboard";
import ExperienceDashboard from "./pages/ExperienceDashboard";
import Ai from "./pages/ChatBot";
const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <ThemeProvider defaultTheme="dark">
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/projects" element={<Projects />} />
            <Route path="/blog" element={<Blog />} />
            <Route path="/academic" element={<Academic />} />
            <Route path="/experience" element={<Experience />} />
            <Route path="/contact" element={<Contact />} />
            <Route path="/login" element={<LoginPage />} />
            {/* <Route path="/dashboard" element={<DashboardPage />} /> */}
            <Route path="/forecast" element={<ForecastPage />} />
            {/* <Route path="/dashboardproject" element={<DashbroadProject />} /> */}
            <Route path="/dashboard" element={<DashboardLayout />}>
              <Route index element={<BlogDashboard />} />
              <Route path="projects" element={<ProjectDashboard />} />
              <Route path="academic" element={<AcademicDashboard />} />
              <Route path="experience" element={<ExperienceDashboard />} />
            </Route>
            <Route path="/ai" element={<Ai />} />
            {/* Add more routes as needed */}
            {/* Catch-all route for 404 Not Found */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </TooltipProvider>
    </ThemeProvider>
  </QueryClientProvider>
);

export default App;
