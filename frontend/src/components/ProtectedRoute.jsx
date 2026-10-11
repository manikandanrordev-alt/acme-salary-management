import { Navigate, Outlet } from 'react-router-dom'
import { Box, CircularProgress, Typography, Container, Alert } from '@mui/material'
import { useAuth } from '../context/AuthContext'

export default function ProtectedRoute({ requireHr = false }) {
  const { loading, isAuthenticated, isHrManager } = useAuth()

  if (loading) {
    return (
      <Box
        sx={{
          minHeight: '70vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 2,
        }}
      >
        <CircularProgress size={40} color="primary" />
        <Typography color="text.secondary">Verifying enterprise session...</Typography>
      </Box>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }

  if (requireHr && !isHrManager) {
    return (
      <Container maxWidth="md" sx={{ py: 8 }}>
        <Alert severity="error">
          Access Denied: You do not possess HR Manager or Administrator privileges.
        </Alert>
      </Container>
    )
  }

  return <Outlet />
}
