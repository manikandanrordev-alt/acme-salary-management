import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container,
  Box,
  Typography,
  Card,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  TextField,
  MenuItem,
  Chip,
  IconButton,
  Button,
  Stack,
  InputAdornment,
  CircularProgress,
  Alert,
  Tooltip,
} from '@mui/material'
import SearchIcon from '@mui/icons-material/Search'
import VisibilityIcon from '@mui/icons-material/Visibility'
import ClearIcon from '@mui/icons-material/Clear'
import FilterListIcon from '@mui/icons-material/FilterList'
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward'
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward'
import FileDownloadIcon from '@mui/icons-material/FileDownload'
import FileUploadIcon from '@mui/icons-material/FileUpload'
import Dialog from '@mui/material/Dialog'
import DialogTitle from '@mui/material/DialogTitle'
import DialogContent from '@mui/material/DialogContent'
import DialogActions from '@mui/material/DialogActions'
import apiClient from '../api/client'
import { useAuth } from '../context/AuthContext'

const COUNTRIES = [
  { code: 'US', label: 'United States (US)' },
  { code: 'GB', label: 'United Kingdom (GB)' },
  { code: 'DE', label: 'Germany (DE)' },
  { code: 'IN', label: 'India (IN)' },
  { code: 'SG', label: 'Singapore (SG)' },
]

const STATUSES = [
  { value: 'active', label: 'Active' },
  { value: 'on_leave', label: 'On Leave' },
  { value: 'terminated', label: 'Terminated' },
]

export default function EmployeeDirectoryPage() {
  const navigate = useNavigate()
  const { isHrManager } = useAuth()

  // Data states
  const [employees, setEmployees] = useState([])
  const [departments, setDepartments] = useState([])
  const [totalCount, setTotalCount] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  // CSV Import/Export states
  const [importOpen, setImportOpen] = useState(false)
  const [importFile, setImportFile] = useState(null)
  const [importing, setImporting] = useState(false)
  const [importResult, setImportResult] = useState(null)
  const [importError, setImportError] = useState(null)

  // Query states
  const [page, setPage] = useState(0)
  const [perPage, setPerPage] = useState(25)
  const [search, setSearch] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [countryCode, setCountryCode] = useState('')
  const [employmentStatus, setEmploymentStatus] = useState('')
  const [sortBy, setSortBy] = useState('employee_code')
  const [sortOrder, setSortOrder] = useState('asc')

  // Debounce search input
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedSearch(search)
      setPage(0)
    }, 350)
    return () => clearTimeout(handler)
  }, [search])

  // Fetch departments for filter dropdown
  useEffect(() => {
    apiClient
      .get('/api/v1/departments')
      .then((res) => setDepartments(res.data.data || []))
      .catch(() => {})
  }, [])

  // Fetch employees
  const fetchEmployees = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const params = {
        page: page + 1,
        per_page: perPage,
        sort_by: sortBy,
        sort_order: sortOrder,
      }
      if (debouncedSearch) params.search = debouncedSearch
      if (departmentId) params.department_id = departmentId
      if (countryCode) params.country_code = countryCode
      if (employmentStatus) params.employment_status = employmentStatus

      const res = await apiClient.get('/api/v1/employees', { params })
      setEmployees(res.data.data || [])
      setTotalCount(res.data.meta?.total_count || 0)
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to fetch employees')
    } finally {
      setLoading(false)
    }
  }, [page, perPage, debouncedSearch, departmentId, countryCode, employmentStatus, sortBy, sortOrder])

  useEffect(() => {
    fetchEmployees()
  }, [fetchEmployees])

  const handleSort = (column) => {
    if (sortBy === column) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')
    } else {
      setSortBy(column)
      setSortOrder('asc')
    }
  }

  const handleResetFilters = () => {
    setSearch('')
    setDebouncedSearch('')
    setDepartmentId('')
    setCountryCode('')
    setEmploymentStatus('')
    setSortBy('employee_code')
    setSortOrder('asc')
    setPage(0)
  }

  const formatCurrency = (amount, currency) => {
    if (!amount) return 'N/A'
    const num = Number(amount)
    const inrAmount = currency === 'INR' || num >= 300000 ? num : num * 85
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0,
    }).format(inrAmount)
  }

  const getStatusChip = (status) => {
    switch (status) {
      case 'active':
        return <Chip label="Active" color="success" size="small" variant="outlined" />
      case 'on_leave':
        return <Chip label="On Leave" color="warning" size="small" variant="outlined" />
      case 'terminated':
        return <Chip label="Terminated" color="error" size="small" variant="outlined" />
      default:
        return <Chip label={status} size="small" />
    }
  }

  const handleExportCsv = async () => {
    try {
      const params = {}
      if (debouncedSearch) params.search = debouncedSearch
      if (departmentId) params.department_id = departmentId
      if (countryCode) params.country_code = countryCode
      if (employmentStatus) params.employment_status = employmentStatus

      const res = await apiClient.get('/api/v1/employees/export', {
        params,
        responseType: 'blob',
      })

      const blob = new Blob([res.data], { type: 'text/csv;charset=utf-8;' })
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `acme_employees_${new Date().toISOString().slice(0, 10)}.csv`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
    } catch {
      setError('Failed to export employee CSV')
    }
  }

  const handleImportSubmit = async (e) => {
    e.preventDefault()
    if (!importFile) {
      setImportError('Please select a CSV file to upload')
      return
    }

    setImporting(true)
    setImportError(null)
    setImportResult(null)

    try {
      const formData = new FormData()
      formData.append('file', importFile)

      const res = await apiClient.post('/api/v1/employees/import', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      setImportResult(res.data.data)
      fetchEmployees()
    } catch (err) {
      const data = err.response?.data?.data
      if (data) {
        setImportResult(data)
      } else {
        setImportError(err.response?.data?.error?.message || 'Failed to import CSV file')
      }
    } finally {
      setImporting(false)
    }
  }

  return (
    <Container maxWidth="xl" sx={{ py: 4 }}>
      {/* Page Header */}
      <Box sx={{ mb: 4, display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 2 }}>
        <Box>
          <Typography variant="h4" component="h1" fontWeight={800} gutterBottom>
            Employee Directory
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Manage enterprise personnel records, view active compensation, and track historical revisions across {totalCount.toLocaleString()} employees.
          </Typography>
        </Box>

        <Stack direction="row" spacing={1.5}>
          <Button
            variant="outlined"
            startIcon={<FileDownloadIcon />}
            onClick={handleExportCsv}
            size="small"
            sx={{ textTransform: 'none', fontWeight: 600 }}
          >
            Export CSV
          </Button>
          {isHrManager && (
            <Button
              variant="contained"
              startIcon={<FileUploadIcon />}
              onClick={() => {
                setImportOpen(true)
                setImportFile(null)
                setImportResult(null)
                setImportError(null)
              }}
              size="small"
              sx={{ textTransform: 'none', fontWeight: 600 }}
            >
              Import CSV
            </Button>
          )}
        </Stack>
      </Box>

      {/* Filter and Search Bar */}
      <Card sx={{ p: 2.5, mb: 3, bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems="center">
          <TextField
            placeholder="Search by name, email, or code (e.g. ACME-00101)..."
            size="small"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            sx={{ flex: 2, minWidth: { xs: '100%', md: 320 } }}
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon color="action" />
                  </InputAdornment>
                ),
                endAdornment: search && (
                  <InputAdornment position="end">
                    <IconButton size="small" onClick={() => setSearch('')}>
                      <ClearIcon fontSize="small" />
                    </IconButton>
                  </InputAdornment>
                ),
              },
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
            sx={{ minWidth: 160 }}
          >
            <MenuItem value="">All Departments</MenuItem>
            {departments.map((d) => (
              <MenuItem key={d.id} value={d.id}>
                {d.name} ({d.code})
              </MenuItem>
            ))}
          </TextField>

          <TextField
            select
            label="Country"
            size="small"
            value={countryCode}
            onChange={(e) => {
              setCountryCode(e.target.value)
              setPage(0)
            }}
            sx={{ minWidth: 140 }}
          >
            <MenuItem value="">All Countries</MenuItem>
            {COUNTRIES.map((c) => (
              <MenuItem key={c.code} value={c.code}>
                {c.label}
              </MenuItem>
            ))}
          </TextField>

          <TextField
            select
            label="Status"
            size="small"
            value={employmentStatus}
            onChange={(e) => {
              setEmploymentStatus(e.target.value)
              setPage(0)
            }}
            sx={{ minWidth: 140 }}
          >
            <MenuItem value="">All Statuses</MenuItem>
            {STATUSES.map((s) => (
              <MenuItem key={s.value} value={s.value}>
                {s.label}
              </MenuItem>
            ))}
          </TextField>

          <Button
            variant="text"
            color="inherit"
            size="small"
            startIcon={<FilterListIcon />}
            onClick={handleResetFilters}
            sx={{ textTransform: 'none', whiteSpace: 'nowrap' }}
          >
            Reset Filters
          </Button>
        </Stack>
      </Card>

      {/* Directory Table */}
      <Card sx={{ bgcolor: '#111827', border: '1px solid #1f2937', borderRadius: 2 }}>
        {error && (
          <Alert severity="error" sx={{ m: 2 }}>
            {error}
          </Alert>
        )}

        <TableContainer>
          <Table sx={{ minWidth: 750 }}>
            <TableHead sx={{ bgcolor: '#1f2937' }}>
              <TableRow>
                <TableCell
                  onClick={() => handleSort('employee_code')}
                  sx={{ cursor: 'pointer', fontWeight: 700, color: '#e5e7eb' }}
                >
                  <Stack direction="row" alignItems="center" spacing={0.5}>
                    <span>Employee Code</span>
                    {sortBy === 'employee_code' &&
                      (sortOrder === 'asc' ? <ArrowUpwardIcon fontSize="inherit" /> : <ArrowDownwardIcon fontSize="inherit" />)}
                  </Stack>
                </TableCell>
                <TableCell
                  onClick={() => handleSort('name')}
                  sx={{ cursor: 'pointer', fontWeight: 700, color: '#e5e7eb' }}
                >
                  <Stack direction="row" alignItems="center" spacing={0.5}>
                    <span>Full Name</span>
                    {sortBy === 'name' &&
                      (sortOrder === 'asc' ? <ArrowUpwardIcon fontSize="inherit" /> : <ArrowDownwardIcon fontSize="inherit" />)}
                  </Stack>
                </TableCell>
                <TableCell
                  onClick={() => handleSort('department')}
                  sx={{ cursor: 'pointer', fontWeight: 700, color: '#e5e7eb' }}
                >
                  <Stack direction="row" alignItems="center" spacing={0.5}>
                    <span>Department</span>
                    {sortBy === 'department' &&
                      (sortOrder === 'asc' ? <ArrowUpwardIcon fontSize="inherit" /> : <ArrowDownwardIcon fontSize="inherit" />)}
                  </Stack>
                </TableCell>
                <TableCell
                  onClick={() => handleSort('country_code')}
                  sx={{ cursor: 'pointer', fontWeight: 700, color: '#e5e7eb' }}
                >
                  <Stack direction="row" alignItems="center" spacing={0.5}>
                    <span>Country</span>
                    {sortBy === 'country_code' &&
                      (sortOrder === 'asc' ? <ArrowUpwardIcon fontSize="inherit" /> : <ArrowDownwardIcon fontSize="inherit" />)}
                  </Stack>
                </TableCell>
                <TableCell
                  onClick={() => handleSort('employment_status')}
                  sx={{ cursor: 'pointer', fontWeight: 700, color: '#e5e7eb' }}
                >
                  <Stack direction="row" alignItems="center" spacing={0.5}>
                    <span>Status</span>
                    {sortBy === 'employment_status' &&
                      (sortOrder === 'asc' ? <ArrowUpwardIcon fontSize="inherit" /> : <ArrowDownwardIcon fontSize="inherit" />)}
                  </Stack>
                </TableCell>
                <TableCell sx={{ fontWeight: 700, color: '#e5e7eb' }}>Current Active Salary</TableCell>
                <TableCell
                  onClick={() => handleSort('hire_date')}
                  sx={{ cursor: 'pointer', fontWeight: 700, color: '#e5e7eb' }}
                >
                  <Stack direction="row" alignItems="center" spacing={0.5}>
                    <span>Hire Date</span>
                    {sortBy === 'hire_date' &&
                      (sortOrder === 'asc' ? <ArrowUpwardIcon fontSize="inherit" /> : <ArrowDownwardIcon fontSize="inherit" />)}
                  </Stack>
                </TableCell>
                <TableCell align="right" sx={{ fontWeight: 700, color: '#e5e7eb' }}>
                  Action
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 6 }}>
                    <CircularProgress size={36} />
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                      Loading employee records...
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : employees.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 6 }}>
                    <Typography variant="body1" color="text.secondary">
                      No matching employee records found.
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                employees.map((emp) => (
                  <TableRow
                    key={emp.id}
                    hover
                    sx={{
                      cursor: 'pointer',
                      '&:hover': { bgcolor: 'rgba(255, 255, 255, 0.04)' },
                    }}
                    onClick={() => navigate(`/employees/${emp.id}`)}
                  >
                    <TableCell sx={{ fontFamily: 'monospace', fontWeight: 600, color: '#38bdf8' }}>
                      {emp.employee_code}
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" fontWeight={600}>
                        {emp.full_name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {emp.job_title}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip label={emp.department?.name || 'Unassigned'} size="small" variant="filled" />
                    </TableCell>
                    <TableCell>
                      <Chip label={emp.country_code} size="small" sx={{ fontWeight: 700 }} />
                    </TableCell>
                    <TableCell>{getStatusChip(emp.employment_status)}</TableCell>
                    <TableCell>
                      {emp.current_salary ? (
                        <Box>
                          <Typography variant="body2" fontWeight={700} color="#34d399">
                            {formatCurrency(emp.current_salary.amount, emp.current_salary.currency)}
                          </Typography>
                          <Typography variant="caption" color="text.secondary">
                            {emp.current_salary.currency} &bull; {emp.current_salary.pay_frequency}
                          </Typography>
                        </Box>
                      ) : (
                        <Typography variant="caption" color="text.secondary">
                          No Active Record
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell sx={{ color: 'text.secondary', fontSize: '0.875rem' }}>
                      {emp.hire_date}
                    </TableCell>
                    <TableCell align="right" onClick={(e) => e.stopPropagation()}>
                      <Tooltip title="View & Revise Salary">
                        <IconButton
                          color="primary"
                          size="small"
                          onClick={() => navigate(`/employees/${emp.id}`)}
                        >
                          <VisibilityIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
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
          rowsPerPage={perPage}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          onRowsPerPageChange={(e) => {
            setPerPage(parseInt(e.target.value, 10))
            setPage(0)
          }}
          sx={{ borderTop: '1px solid #1f2937' }}
        />
      </Card>

      {/* CSV Import Dialog */}
      <Dialog open={importOpen} onClose={() => !importing && setImportOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ bgcolor: '#111827', borderBottom: '1px solid #1f2937' }}>
          Bulk Employee & Compensation Import
        </DialogTitle>
        <Box component="form" onSubmit={handleImportSubmit} noValidate>
          <DialogContent sx={{ bgcolor: '#111827', py: 3 }}>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Upload a UTF-8 encoded CSV file with columns: <code>employee_code, first_name, last_name, email, department, country_code (US/GB/DE/IN/SG), employment_status, hire_date (YYYY-MM-DD), current_salary, currency, pay_frequency</code>.
            </Typography>

            {importError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {importError}
              </Alert>
            )}

            {importResult && (
              <Box sx={{ mb: 2 }}>
                <Alert severity={importResult.errors?.length ? 'warning' : 'success'} sx={{ mb: 1 }}>
                  Processed {importResult.total_rows} rows &bull; Successfully created {importResult.created_count} employees &bull; {importResult.errors?.length || 0} validation errors
                </Alert>

                {importResult.errors?.length > 0 && (
                  <TableContainer sx={{ maxHeight: 200, bgcolor: '#1f2937', borderRadius: 1 }}>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell sx={{ color: '#e5e7eb', fontWeight: 700 }}>Row</TableCell>
                          <TableCell sx={{ color: '#e5e7eb', fontWeight: 700 }}>Code</TableCell>
                          <TableCell sx={{ color: '#e5e7eb', fontWeight: 700 }}>Validation Errors</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {importResult.errors.map((err, idx) => (
                          <TableRow key={idx}>
                            <TableCell>{err.row}</TableCell>
                            <TableCell sx={{ fontFamily: 'monospace' }}>{err.code}</TableCell>
                            <TableCell sx={{ color: '#f87171' }}>{err.errors.join('; ')}</TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}
              </Box>
            )}

            <Box sx={{ border: '2px dashed #374151', p: 3, borderRadius: 2, textAlign: 'center', bgcolor: '#0b0f19' }}>
              <input
                type="file"
                accept=".csv,text/csv"
                id="csv-file-input"
                style={{ display: 'none' }}
                onChange={(e) => {
                  setImportFile(e.target.files?.[0] || null)
                  setImportError(null)
                }}
              />
              <label htmlFor="csv-file-input">
                <Button variant="outlined" component="span" startIcon={<FileUploadIcon />} sx={{ textTransform: 'none' }}>
                  {importFile ? importFile.name : 'Choose CSV File'}
                </Button>
              </label>
              {importFile && (
                <Typography variant="caption" sx={{ display: 'block', mt: 1, color: '#34d399' }}>
                  Ready to upload: {importFile.name} ({(importFile.size / 1024).toFixed(1)} KB)
                </Typography>
              )}
            </Box>
          </DialogContent>
          <DialogActions sx={{ bgcolor: '#111827', borderTop: '1px solid #1f2937', p: 2 }}>
            <Button onClick={() => setImportOpen(false)} disabled={importing}>
              Close
            </Button>
            <Button
              type="submit"
              variant="contained"
              disabled={importing || !importFile}
              startIcon={importing ? <CircularProgress size={16} /> : <FileUploadIcon />}
            >
              {importing ? 'Processing Import...' : 'Execute Import'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>
    </Container>
  )
}
