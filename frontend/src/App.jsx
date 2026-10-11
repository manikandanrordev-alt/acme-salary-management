import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { ThemeProvider, createTheme, CssBaseline, Box } from '@mui/material'
import { AuthProvider } from './context/AuthContext'
import Navbar from './components/Navbar'
import ProtectedRoute from './components/ProtectedRoute'
import LoginPage from './pages/LoginPage'
import EmployeeDirectoryPage from './pages/EmployeeDirectoryPage'
import EmployeeDetailPage from './pages/EmployeeDetailPage'
import AnalyticsPage from './pages/AnalyticsPage'
import PayslipsPage from './pages/PayslipsPage'
import AiAdvisorPage from './pages/AiAdvisorPage'
import HrSuitePage from './pages/HrSuitePage'
import HealthPage from './pages/HealthPage'

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#38bdf8',
    },
    secondary: {
      main: '#34d399',
    },
    background: {
      default: '#080c14',
      paper: '#0f172a',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
  },
})

export default function App() {
  return (
    <ThemeProvider theme={darkTheme}>
      <CssBaseline />
      <AuthProvider>
        <BrowserRouter>
          <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
            <Navbar />
            <Box component="main" sx={{ flex: 1 }}>
              <Routes>
                <Route path="/login" element={<LoginPage />} />

                <Route element={<ProtectedRoute />}>
                  <Route path="/" element={<Navigate to="/employees" replace />} />
                  <Route path="/employees" element={<EmployeeDirectoryPage />} />
                  <Route path="/employees/:id" element={<EmployeeDetailPage />} />
                  <Route path="/payslips" element={<PayslipsPage />} />
                  <Route path="/hr-suite" element={<HrSuitePage />} />
                  <Route path="/analytics" element={<AnalyticsPage />} />
                  <Route path="/ai-advisor" element={<AiAdvisorPage />} />
                  <Route path="/health" element={<HealthPage />} />
                </Route>

                <Route path="*" element={<Navigate to="/employees" replace />} />
              </Routes>
            </Box>
          </Box>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  )
}
