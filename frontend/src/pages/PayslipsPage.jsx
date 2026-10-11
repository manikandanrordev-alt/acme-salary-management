import { useState, useEffect, useCallback } from 'react'
import {
  Container,
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  MenuItem,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Chip,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControlLabel,
  Checkbox,
  Stack,
  InputAdornment,
} from '@mui/material'
import SearchIcon from '@mui/icons-material/Search'
import VisibilityIcon from '@mui/icons-material/Visibility'
import EmailIcon from '@mui/icons-material/Email'
import SendIcon from '@mui/icons-material/Send'
import RefreshIcon from '@mui/icons-material/Refresh'
import AutoFixHighIcon from '@mui/icons-material/AutoFixHigh'
import CelebrationIcon from '@mui/icons-material/Celebration'
import AccountBalanceIcon from '@mui/icons-material/AccountBalance'
import CheckCircleIcon from '@mui/icons-material/CheckCircle'
import apiClient from '../api/client'
import { useAuth } from '../context/AuthContext'
import { formatINR, formatLakhsCrores } from '../utils/currency'
import PayslipModal from '../components/PayslipModal'

const MONTH_OPTIONS = [
  { value: '2026-10', label: 'October 2026 (Diwali Festive Month)' },
  { value: '2026-09', label: 'September 2026' },
  { value: '2026-08', label: 'August 2026' },
  { value: '2026-07', label: 'July 2026' },
  { value: '2026-06', label: 'June 2026' },
]

export default function PayslipsPage() {
  const { isHrManager } = useAuth()
  const [payslips, setPayslips] = useState([])
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [successMsg, setSuccessMsg] = useState('')

  // Filters
  const [selectedMonth, setSelectedMonth] = useState('2026-10')
  const [search, setSearch] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [departments, setDepartments] = useState([])
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(25)
  const [totalCount, setTotalCount] = useState(0)

  // Selected Payslip for Modal
  const [activePayslip, setActivePayslip] = useState(null)
  const [modalOpen, setModalOpen] = useState(false)

  // Generate Batch Dialog
  const [generateOpen, setGenerateOpen] = useState(false)
  const [includeDiwali, setIncludeDiwali] = useState(true)
  const [bonusPercentage, setBonusPercentage] = useState(8.33)
  const [generating, setGenerating] = useState(false)

  // Batch Email Dispatch
  const [dispatchingBatch, setDispatchingBatch] = useState(false)

  // Fetch departments
  useEffect(() => {
    apiClient.get('/api/v1/departments')
      .then((res) => setDepartments(res.data.data || []))
      .catch(() => {})
  }, [])

  // Fetch payslips
  const fetchPayslips = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const params = {
        payroll_month: selectedMonth,
        page: page + 1,
        per_page: rowsPerPage,
      }
      if (search) params.search = search
      if (departmentId) params.department_id = departmentId

      const res = await apiClient.get('/api/v1/payslips', { params })
      setPayslips(res.data.data || [])
      setTotalCount(res.data.meta?.total_count || 0)
      setSummary(res.data.summary || null)
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to fetch payslips')
    } finally {
      setLoading(false)
    }
  }, [selectedMonth, page, rowsPerPage, search, departmentId])

  useEffect(() => {
    fetchPayslips()
  }, [fetchPayslips])

  const handleOpenPayslip = (payslip) => {
    setActivePayslip(payslip)
    setModalOpen(true)
  }

  const handleSendSingleEmail = async (id, e) => {
    e.stopPropagation()
    try {
      const res = await apiClient.post(`/api/v1/payslips/${id}/send_email`)
      setSuccessMsg(res.data.message || 'Payslip emailed successfully!')
      fetchPayslips()
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to dispatch email')
    }
  }

  const handleBatchGenerate = async () => {
    setGenerating(true)
    try {
      const res = await apiClient.post('/api/v1/payslips/generate_batch', {
        payroll_month: selectedMonth,
        include_diwali_bonus: includeDiwali,
        bonus_percentage: Number(bonusPercentage),
        limit: 100,
      })
      setSuccessMsg(res.data.message || 'Batch payroll generated successfully!')
      setGenerateOpen(false)
      fetchPayslips()
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to generate payroll')
    } finally {
      setGenerating(false)
    }
  }

  const handleBatchEmailDispatch = async () => {
    if (!window.confirm(`Are you sure you want to dispatch all generated payslip emails for ${selectedMonth}?`)) {
      return
    }
    setDispatchingBatch(true)
    try {
      const res = await apiClient.post('/api/v1/payslips/send_batch_emails', {
        payroll_month: selectedMonth,
      })
      setSuccessMsg(res.data.message || 'Batch emails sent successfully!')
      fetchPayslips()
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to dispatch batch emails')
    } finally {
      setDispatchingBatch(false)
    }
  }

  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      {/* Page Header */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <AccountBalanceIcon sx={{ color: '#38bdf8', fontSize: 36 }} />
            <Typography variant="h4" component="h1" fontWeight={900}>
              Monthly Payroll & Payslips
            </Typography>
          </Box>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
            Indian Statutory Compliance (EPF, PT, TDS New Tax Regime), Festive Diwali Bonus, and Automated Email Delivery.
          </Typography>
        </Box>

        {isHrManager && (
          <Stack direction="row" spacing={1.5}>
            <Button
              variant="outlined"
              color="primary"
              startIcon={<AutoFixHighIcon />}
              onClick={() => setGenerateOpen(true)}
              sx={{ textTransform: 'none', fontWeight: 700 }}
            >
              Run Monthly Payroll
            </Button>
            <Button
              variant="contained"
              color="success"
              startIcon={dispatchingBatch ? <CircularProgress size={16} color="inherit" /> : <SendIcon />}
              onClick={handleBatchEmailDispatch}
              disabled={dispatchingBatch}
              sx={{ textTransform: 'none', fontWeight: 700 }}
            >
              {dispatchingBatch ? 'Dispatching...' : 'Dispatch All Emails'}
            </Button>
          </Stack>
        )}
      </Box>

      {/* Alerts */}
      {successMsg && (
        <Alert severity="success" sx={{ mb: 3 }} onClose={() => setSuccessMsg('')} icon={<CheckCircleIcon />}>
          {successMsg}
        </Alert>
      )}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Summary KPI Cards */}
      {summary && (
        <Grid container spacing={2.5} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 2.5 }}>
                <Typography variant="caption" color="text.secondary" fontWeight={600}>
                  GROSS PAYROLL (₹)
                </Typography>
                <Typography variant="h5" fontWeight={900} color="#38bdf8" sx={{ mt: 0.5 }}>
                  {formatLakhsCrores(summary.total_gross_inr)}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Total earnings commitment
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 2.5 }}>
                <Typography variant="caption" color="text.secondary" fontWeight={600}>
                  NET DISBURSED (₹)
                </Typography>
                <Typography variant="h5" fontWeight={900} color="#34d399" sx={{ mt: 0.5 }}>
                  {formatLakhsCrores(summary.total_net_disbursed_inr)}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Direct take-home payout
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 2.5 }}>
                <Typography variant="caption" color="text.secondary" fontWeight={600}>
                  TDS TAX DEDUCTION (₹)
                </Typography>
                <Typography variant="h5" fontWeight={900} color="#f59e0b" sx={{ mt: 0.5 }}>
                  {formatLakhsCrores(summary.total_tds_tax_inr)}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Govt Income Tax remittance
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 2.5 }}>
                <Typography variant="caption" color="text.secondary" fontWeight={600}>
                  🪔 DIWALI BONUS POOL (₹)
                </Typography>
                <Typography variant="h5" fontWeight={900} color="#c084fc" sx={{ mt: 0.5 }}>
                  {formatLakhsCrores(summary.total_diwali_bonus_inr)}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Annual festive payout
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={2.4}>
            <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
              <CardContent sx={{ p: 2.5 }}>
                <Typography variant="caption" color="text.secondary" fontWeight={600}>
                  EMAILS DISPATCHED
                </Typography>
                <Typography variant="h5" fontWeight={900} color="#60a5fa" sx={{ mt: 0.5 }}>
                  {summary.total_dispatched_emails} / {summary.total_payslips}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {summary.total_payslips > 0
                    ? `${Math.round((summary.total_dispatched_emails / summary.total_payslips) * 100)}% delivered to inboxes`
                    : 'Pending generation'}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}

      {/* Filter and Control Bar */}
      <Card sx={{ p: 2.5, mb: 3, bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems="center">
          <TextField
            select
            label="Payroll Month"
            size="small"
            value={selectedMonth}
            onChange={(e) => {
              setSelectedMonth(e.target.value)
              setPage(0)
            }}
            sx={{ minWidth: 260 }}
          >
            {MONTH_OPTIONS.map((opt) => (
              <MenuItem key={opt.value} value={opt.value}>
                {opt.label}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            placeholder="Search employee name, code, or email..."
            size="small"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            sx={{ flex: 1, minWidth: { xs: '100%', md: 280 } }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon color="action" />
                </InputAdornment>
              ),
            }}
          />

          <TextField
            select
            label="Department"
            size="small"
            value={departmentId}
            onChange={(e) => {
              setDepartmentId(e.target.value)
              setPage(0)
            }}
            sx={{ minWidth: 180 }}
          >
            <MenuItem value="">All Departments</MenuItem>
            {departments.map((d) => (
              <MenuItem key={d.id} value={d.id}>
                {d.name} ({d.code})
              </MenuItem>
            ))}
          </TextField>

          <Button
            variant="text"
            startIcon={<RefreshIcon />}
            onClick={fetchPayslips}
            sx={{ textTransform: 'none', whiteSpace: 'nowrap' }}
          >
            Refresh
          </Button>
        </Stack>
      </Card>

      {/* Payslips Table */}
      <Card sx={{ bgcolor: '#0f172a', border: '1px solid #1e293b', borderRadius: 2 }}>
        <TableContainer>
          <Table sx={{ minWidth: 850 }}>
            <TableHead sx={{ bgcolor: '#1e293b' }}>
              <TableRow>
                <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Employee</TableCell>
                <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Department</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Basic Pay (₹)</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Diwali Bonus (₹)</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>TDS Tax (₹)</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Total Deductions (₹)</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Net Salary (₹)</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Email Status</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={9} align="center" sx={{ py: 6 }}>
                    <CircularProgress size={36} />
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                      Loading monthly payslip records...
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : payslips.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={9} align="center" sx={{ py: 6 }}>
                    <Typography variant="body1" color="text.secondary">
                      No payslips generated for this period yet. Click "Run Monthly Payroll" above to generate!
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                payslips.map((p) => (
                  <TableRow
                    key={p.id}
                    hover
                    sx={{ cursor: 'pointer', '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.04)' } }}
                    onClick={() => handleOpenPayslip(p)}
                  >
                    <TableCell>
                      <Typography variant="body2" fontWeight={700}>
                        {p.employee?.full_name}
                      </Typography>
                      <Typography variant="caption" sx={{ fontFamily: 'monospace', color: '#38bdf8' }}>
                        {p.employee?.employee_code}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip label={p.employee?.department?.code || 'N/A'} size="small" variant="outlined" />
                    </TableCell>
                    <TableCell align="right" sx={{ fontWeight: 600 }}>
                      {formatINR(p.basic_pay)}
                    </TableCell>
                    <TableCell align="right">
                      {p.diwali_bonus > 0 ? (
                        <Typography variant="body2" fontWeight={700} color="#f59e0b">
                          {formatINR(p.diwali_bonus)}
                        </Typography>
                      ) : (
                        '-'
                      )}
                    </TableCell>
                    <TableCell align="right" sx={{ color: '#f87171' }}>
                      {formatINR(p.tds_tax_deduction)}
                    </TableCell>
                    <TableCell align="right" sx={{ color: '#f87171', fontWeight: 600 }}>
                      {formatINR(p.total_deductions)}
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" fontWeight={800} color="#34d399">
                        {formatINR(p.net_pay)}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      {p.status === 'dispatched' ? (
                        <Chip
                          label="Emailed"
                          color="success"
                          size="small"
                          icon={<CheckCircleIcon />}
                          sx={{ fontSize: '0.7rem', fontWeight: 700 }}
                        />
                      ) : (
                        <Chip
                          label="Generated"
                          color="default"
                          size="small"
                          sx={{ fontSize: '0.7rem' }}
                        />
                      )}
                    </TableCell>
                    <TableCell align="right" onClick={(e) => e.stopPropagation()}>
                      <Stack direction="row" spacing={0.5} justifyContent="flex-end">
                        <Tooltip title="View Official Payslip">
                          <IconButton color="primary" size="small" onClick={() => handleOpenPayslip(p)}>
                            <VisibilityIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        {isHrManager && (
                          <Tooltip title="Email to Employee">
                            <IconButton color="success" size="small" onClick={(e) => handleSendSingleEmail(p.id, e)}>
                              <EmailIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        )}
                      </Stack>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          rowsPerPageOptions={[10, 25, 50, 100]}
          component="div"
          count={totalCount}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10))
            setPage(0)
          }}
          sx={{ borderTop: '1px solid #1e293b' }}
        />
      </Card>

      {/* Generate Payroll Dialog */}
      <Dialog open={generateOpen} onClose={() => !generating && setGenerateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ bgcolor: '#0b0f19', borderBottom: '1px solid #1e293b' }}>
          Execute Monthly Payroll & Payslip Run
        </DialogTitle>
        <DialogContent sx={{ bgcolor: '#0b0f19', py: 3 }}>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
            Automate statutory tax calculation (New Tax Regime), EPF (12%), Professional Tax (₹200), and generate formatted payslips in bulk.
          </Typography>

          <Stack spacing={2.5}>
            <TextField
              select
              fullWidth
              label="Select Payroll Month"
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
            >
              {MONTH_OPTIONS.map((opt) => (
                <MenuItem key={opt.value} value={opt.value}>
                  {opt.label}
                </MenuItem>
              ))}
            </TextField>

            <Box sx={{ p: 2, bgcolor: '#1e293b', borderRadius: 2, border: '1px solid #334155' }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <CelebrationIcon sx={{ color: '#f59e0b' }} />
                <Typography variant="subtitle2" fontWeight={700} color="#f59e0b">
                  Diwali Festive Bonus Configuration
                </Typography>
              </Box>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={includeDiwali}
                    onChange={(e) => setIncludeDiwali(e.target.checked)}
                    color="primary"
                  />
                }
                label="Include Annual Diwali Festive Bonus in this Payroll Run"
              />
              {includeDiwali && (
                <TextField
                  fullWidth
                  type="number"
                  label="Bonus Percentage (% of Annual Basic)"
                  value={bonusPercentage}
                  onChange={(e) => setBonusPercentage(e.target.value)}
                  helperText="Statutory minimum under Payment of Bonus Act, 1965 is 8.33%"
                  size="small"
                  sx={{ mt: 1.5 }}
                />
              )}
            </Box>
          </Stack>
        </DialogContent>
        <DialogActions sx={{ bgcolor: '#0b0f19', borderTop: '1px solid #1e293b', p: 2 }}>
          <Button onClick={() => setGenerateOpen(false)} disabled={generating}>
            Cancel
          </Button>
          <Button
            variant="contained"
            color="primary"
            onClick={handleBatchGenerate}
            disabled={generating}
            startIcon={generating ? <CircularProgress size={16} color="inherit" /> : <AutoFixHighIcon />}
          >
            {generating ? 'Calculating Payroll...' : 'Execute Payroll Batch'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Individual Payslip Modal */}
      <PayslipModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        payslip={activePayslip}
        onEmailSent={(updated) => {
          setActivePayslip(updated)
          fetchPayslips()
        }}
      />
    </Container>
  )
}
