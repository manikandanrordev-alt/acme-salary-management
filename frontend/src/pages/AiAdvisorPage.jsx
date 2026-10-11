import { useState, useEffect } from 'react'
import {
  Container,
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Chip,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  CircularProgress,
  Alert,
  Rating,
  Divider,
  Stack,
  LinearProgress,
} from '@mui/material'
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome'
import WarningAmberIcon from '@mui/icons-material/WarningAmber'
import TrendingUpIcon from '@mui/icons-material/TrendingUp'
import SecurityIcon from '@mui/icons-material/Security'
import CelebrationIcon from '@mui/icons-material/Celebration'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import apiClient from '../api/client'
import { formatINR, formatLakhsCrores } from '../utils/currency'

export default function AiAdvisorPage() {
  const [summary, setSummary] = useState(null)
  const [attritionList, setAttritionList] = useState([])
  const [anomalies, setAnomalies] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  // Simulation State
  const [selectedEmpId, setSelectedEmpId] = useState(null)
  const [perfRating, setPerfRating] = useState(4)
  const [simulating, setSimulating] = useState(false)
  const [simulationResult, setSimulationResult] = useState(null)

  useEffect(() => {
    async function loadData() {
      setLoading(true)
      try {
        const [sumRes, attRes, anoRes] = await Promise.all([
          apiClient.get('/api/v1/ai/summary'),
          apiClient.get('/api/v1/ai/attrition_risk'),
          apiClient.get('/api/v1/ai/anomalies'),
        ])
        setSummary(sumRes.data.data)
        setAttritionList(attRes.data.data || [])
        setAnomalies(anoRes.data.data || [])
        if (attRes.data.data?.length > 0) {
          setSelectedEmpId(attRes.data.data[0].employee_id)
        }
      } catch (err) {
        setError(err.response?.data?.error?.message || 'Failed to load AI intelligence data')
      } finally {
        setLoading(false)
      }
    }
    loadData()
  }, [])

  const runSimulation = async (empId, rating) => {
    setSimulating(true)
    setSimulationResult(null)
    try {
      const res = await apiClient.post('/api/v1/ai/salary_recommendation', {
        employee_id: empId,
        performance_rating: rating,
      })
      setSimulationResult(res.data.data)
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to calculate recommendation')
    } finally {
      setSimulating(false)
    }
  }

  const getRiskChip = (level) => {
    switch (level) {
      case 'HIGH':
        return <Chip label="HIGH FLIGHT RISK" color="error" size="small" sx={{ fontWeight: 800, fontSize: '0.65rem' }} />
      case 'MEDIUM':
        return <Chip label="MEDIUM RISK" color="warning" size="small" sx={{ fontWeight: 800, fontSize: '0.65rem' }} />
      default:
        return <Chip label="LOW RISK" color="success" size="small" sx={{ fontWeight: 800, fontSize: '0.65rem' }} />
    }
  }

  if (loading) {
    return (
      <Container maxWidth="xl" sx={{ py: 10, textAlign: 'center' }}>
        <CircularProgress size={44} sx={{ color: '#f59e0b' }} />
        <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
          Aggregating Indian market compensation telemetry & AI attrition models...
        </Typography>
      </Container>
    )
  }

  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      {/* Header */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <AutoAwesomeIcon sx={{ color: '#f59e0b', fontSize: 36 }} />
            <Typography variant="h4" component="h1" fontWeight={900}>
              AI Compensation & Retention Intelligence
            </Typography>
          </Box>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
            Predictive attrition forecasting, Indian market benchmarking (INR), statutory Diwali bonus optimization, and merit increase modeling.
          </Typography>
        </Box>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Summary KPI Cards */}
      {summary && (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="caption" color="text.secondary" fontWeight={700}>
                    AI PAYROLL HEALTH INDEX
                  </Typography>
                  <SecurityIcon sx={{ color: '#10b981', fontSize: 20 }} />
                </Box>
                <Typography variant="h3" fontWeight={900} color="#10b981" sx={{ my: 1 }}>
                  {summary.payroll_health_score} <span style={{ fontSize: '1rem', color: '#94a3b8' }}>/ 100</span>
                </Typography>
                <LinearProgress
                  variant="determinate"
                  value={summary.payroll_health_score}
                  color="success"
                  sx={{ height: 6, borderRadius: 3 }}
                />
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="caption" color="text.secondary" fontWeight={700}>
                    ATTRITION RISK POOL
                  </Typography>
                  <WarningAmberIcon sx={{ color: '#f59e0b', fontSize: 20 }} />
                </Box>
                <Typography variant="h3" fontWeight={900} color="#f59e0b" sx={{ my: 1 }}>
                  {summary.attrition_risk_summary?.high_risk_count} <span style={{ fontSize: '1rem', color: '#94a3b8' }}>High Risk</span>
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Top exposure: <strong>{summary.attrition_risk_summary?.top_risk_department}</strong>
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="caption" color="text.secondary" fontWeight={700}>
                    DIWALI BONUS PROJECTION
                  </Typography>
                  <CelebrationIcon sx={{ color: '#c084fc', fontSize: 20 }} />
                </Box>
                <Typography variant="h4" fontWeight={900} color="#c084fc" sx={{ my: 1 }}>
                  {formatLakhsCrores(summary.festive_bonus_forecast?.projected_diwali_payout)}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {summary.festive_bonus_forecast?.statutory_rate} (Statutory Compliance)
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Typography variant="caption" color="text.secondary" fontWeight={700}>
                    ACTIVE AI RECOMMENDATIONS
                  </Typography>
                  <TrendingUpIcon sx={{ color: '#38bdf8', fontSize: 20 }} />
                </Box>
                <Typography variant="h3" fontWeight={900} color="#38bdf8" sx={{ my: 1 }}>
                  {summary.ai_recommendation_count}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Ready for HR Director approval
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Simulator and Risk Grid */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {/* Attrition Risk Radar Table */}
        <Grid item xs={12} lg={8}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
            <CardContent sx={{ p: 3 }}>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h6" fontWeight={800}>
                  Predictive Flight-Risk Radar (Indian Tech Market Gap)
                </Typography>
                <Chip label="Real-time Telemetry" size="small" color="primary" sx={{ fontSize: '0.7rem' }} />
              </Box>

              <TableContainer>
                <Table size="small">
                  <TableHead sx={{ bgcolor: '#1e293b' }}>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Employee</TableCell>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Current CTC (₹)</TableCell>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Market 75th (₹)</TableCell>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Market Gap</TableCell>
                      <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Risk Status</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Action</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {attritionList.map((emp) => (
                      <TableRow key={emp.employee_id} hover sx={{ '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.04)' } }}>
                        <TableCell>
                          <Typography variant="body2" fontWeight={700}>{emp.full_name}</Typography>
                          <Typography variant="caption" color="text.secondary">
                            {emp.employee_code} &bull; {emp.department}
                          </Typography>
                        </TableCell>
                        <TableCell sx={{ fontWeight: 600 }}>{formatLakhsCrores(emp.current_ctc_inr)}</TableCell>
                        <TableCell sx={{ color: '#38bdf8', fontWeight: 600 }}>{formatLakhsCrores(emp.market_p75_inr)}</TableCell>
                        <TableCell sx={{ color: '#f87171', fontWeight: 700 }}>
                          -{emp.gap_percentage}%
                        </TableCell>
                        <TableCell>{getRiskChip(emp.risk_level)}</TableCell>
                        <TableCell align="right">
                          <Button
                            size="small"
                            variant="outlined"
                            onClick={() => {
                              setSelectedEmpId(emp.employee_id)
                              runSimulation(emp.employee_id, perfRating)
                            }}
                            sx={{ textTransform: 'none', fontSize: '0.75rem' }}
                          >
                            Simulate Raise
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* AI Salary Revision Simulator */}
        <Grid item xs={12} lg={4}>
          <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" fontWeight={800} sx={{ mb: 1, display: 'flex', alignItems: 'center', gap: 1 }}>
                <AutoAwesomeIcon sx={{ color: '#f59e0b' }} /> AI Merit Revision Simulator
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                Calculate optimal merit raises balanced against Indian income tax slabs and take-home salary.
              </Typography>

              <Box sx={{ mb: 3 }}>
                <Typography variant="caption" color="text.secondary" fontWeight={700} sx={{ display: 'block', mb: 1 }}>
                  PERFORMANCE ASSESSMENT RATING
                </Typography>
                <Rating
                  value={perfRating}
                  onChange={(_, val) => setPerfRating(val || 3)}
                  size="large"
                />
              </Box>

              <Button
                fullWidth
                variant="contained"
                color="warning"
                onClick={() => runSimulation(selectedEmpId || attritionList[0]?.employee_id, perfRating)}
                disabled={simulating || !selectedEmpId}
                sx={{ textTransform: 'none', fontWeight: 800, py: 1.2, mb: 3 }}
              >
                {simulating ? <CircularProgress size={20} color="inherit" /> : 'Generate AI Compensation Recommendation'}
              </Button>

              {simulationResult && (
                <Box sx={{ p: 2.5, bgcolor: '#0b0f19', borderRadius: 2, border: '1px solid #334155' }}>
                  <Typography variant="subtitle2" fontWeight={800} color="#38bdf8" gutterBottom>
                    RECOMMENDED REVISION FOR {simulationResult.employee_name}
                  </Typography>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', my: 1 }}>
                    <Typography variant="body2" color="text.secondary">Current CTC:</Typography>
                    <Typography variant="body2" fontWeight={700}>{formatINR(simulationResult.current_ctc_inr)}</Typography>
                  </Box>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', my: 1 }}>
                    <Typography variant="body2" color="text.secondary">AI Proposed CTC:</Typography>
                    <Typography variant="body2" fontWeight={800} color="#34d399">
                      {formatINR(simulationResult.recommended_ctc_inr)} (+{simulationResult.increment_percentage}%)
                    </Typography>
                  </Box>

                  <Divider sx={{ my: 1.5, borderColor: '#334155' }} />

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', my: 1 }}>
                    <Typography variant="body2" color="text.secondary">New Monthly Gross:</Typography>
                    <Typography variant="body2" fontWeight={700}>{formatINR(simulationResult.proposed_monthly_gross)}</Typography>
                  </Box>

                  <Box sx={{ display: 'flex', justifyContent: 'space-between', my: 1 }}>
                    <Typography variant="body2" color="text.secondary">Estimated Monthly TDS:</Typography>
                    <Typography variant="body2" fontWeight={700} color="#f87171">
                      {formatINR(simulationResult.tax_impact?.proposed_monthly_tds)}
                    </Typography>
                  </Box>

                  <Alert severity="info" sx={{ mt: 2, fontSize: '0.8rem' }} icon={<CheckCircleIcon />}>
                    {simulationResult.ai_rationale}
                  </Alert>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Compliance & Anomaly Flags */}
      <Typography variant="h6" fontWeight={800} sx={{ mb: 2 }}>
        AI Payroll Anomaly & Compliance Watchdog
      </Typography>
      <Grid container spacing={2.5}>
        {anomalies.map((ano) => (
          <Grid item xs={12} md={4} key={ano.id}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 2.5 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                  <Chip
                    label={ano.severity}
                    color={ano.severity === 'HIGH' ? 'error' : ano.severity === 'MEDIUM' ? 'warning' : 'primary'}
                    size="small"
                    sx={{ fontSize: '0.65rem', fontWeight: 800 }}
                  />
                  <Typography variant="caption" sx={{ fontFamily: 'monospace', color: '#94a3b8' }}>
                    {ano.type}
                  </Typography>
                </Box>
                <Typography variant="subtitle2" fontWeight={700} sx={{ my: 1 }}>
                  {ano.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ fontSize: '0.85rem', mb: 2 }}>
                  {ano.description}
                </Typography>
                <Box sx={{ p: 1.5, bgcolor: '#1e293b', borderRadius: 1.5 }}>
                  <Typography variant="caption" color="#38bdf8" fontWeight={600}>
                    Suggested Action:
                  </Typography>
                  <Typography variant="caption" color="text.primary" sx={{ display: 'block', mt: 0.3 }}>
                    {ano.suggested_action}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Container>
  )
}
