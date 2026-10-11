import { Container, Typography, Card, CardContent } from '@mui/material'

export default function AnalyticsPage() {
  return (
    <Container maxWidth="lg" sx={{ py: 6 }}>
      <Typography variant="h4" fontWeight={800} gutterBottom>
        Compensation Analytics & Intelligence
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 4 }}>
        Multi-currency salary distributions, department averages, and headcount metrics.
      </Typography>

      <Card sx={{ bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 3, p: 4, textAlign: 'center' }}>
        <CardContent>
          <Typography variant="h6" color="primary" gutterBottom>
            Analytics Module
          </Typography>
          <Typography color="text.secondary">
            Multi-currency payroll aggregations will load here.
          </Typography>
        </CardContent>
      </Card>
    </Container>
  )
}
