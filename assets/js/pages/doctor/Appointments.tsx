import { useMemo, useState } from 'react'
import {
  Avatar,
  Button,
  Card,
  Col,
  Flex,
  Input,
  DatePicker,
  TimePicker,
  Popconfirm,
  Row,
  Segmented,
  Space,
  Table,
  Tag,
  Typography,
  theme
} from 'antd'
import {
  IconCalendarEvent,
  IconCheck,
  IconCircleX,
  IconClock,
  IconMapPin,
  IconNotes,
  IconUser,
  IconVideo,
  IconX,
  IconArrowBackUp
} from '@tabler/icons-react'
import dayjs from 'dayjs'
import type { Dayjs } from 'dayjs'
import { format, formatDistanceToNow } from 'date-fns'
import { enUS, el } from 'date-fns/locale'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'

import type { AppPageProps } from '@/types/app'

const { Title, Text } = Typography
const { useToken } = theme

const DATE_LOCALES: Record<string, any> = {
  en: enUS,
  el: el
}

type Appointment = {
  id: string
  startsAt: string
  status: string
  consultationMode?: string
  appointmentTypeName?: string | null
  pendingExpiresAt?: string | null
  notes?: string | null
  rescheduledFromAppointmentId?: string | null
  patient?: {
    id: string
    firstName: string
    lastName: string
    phone?: string | null
    avatarUrl?: string | null
  }
}

type PageProps = AppPageProps<{
  appointments?: Appointment[]
  counts?: {
    total: number
    pending: number
    upcoming: number
    completed: number
  }
}>

const statusColor = (status: string) => {
  switch (status) {
    case 'confirmed':
      return 'success'
    case 'pending':
    case 'held':
      return 'warning'
    case 'cancelled':
    case 'no_show':
      return 'error'
    default:
      return 'default'
  }
}

const modeLabel = (mode?: string, t?: any) => {
  if (!mode) return t ? t('In-person') : 'In-person'
  if (mode === 'telemedicine' || mode === 'video') return t ? t('Telemedicine') : 'Telemedicine'
  return t ? t('In-person') : 'In-person'
}

const DoctorAppointmentsPage = ({ appointments = [], counts }: PageProps) => {
  const { t, i18n } = useTranslation('default')
  const { token } = useToken()
  const [filter, setFilter] = useState<string>('all')
  const [reasonModal, setReasonModal] = useState<{ id: string | null; action: 'reject' }>({
    id: null,
    action: 'reject'
  })
  const [reason, setReason] = useState('')
  const [rescheduleModal, setRescheduleModal] = useState<{ id: string | null; when: dayjs.Dayjs | null }>({ id: null, when: null })

  const dateLocale = DATE_LOCALES[i18n.language] || enUS

  const filteredAppointments = useMemo(() => {
    if (filter === 'all') return appointments
    if (filter === 'pending') return appointments.filter((a: Appointment) => a.status === 'pending')
    if (filter === 'upcoming') return appointments.filter((a: Appointment) => ['pending', 'confirmed', 'held'].includes(a.status))
    if (filter === 'completed') return appointments.filter((a: Appointment) => a.status === 'completed')
    if (filter === 'cancelled') return appointments.filter((a: Appointment) => a.status === 'cancelled' || a.status === 'no_show')
    return appointments
  }, [appointments, filter])

  const handleApprove = (id: string) => {
    router.post(`/dashboard/doctor/appointments/${id}/approve`, {}, { preserveScroll: true })
  }

  const handleReject = () => {
    if (!reasonModal.id) return
    router.post(`/dashboard/doctor/appointments/${reasonModal.id}/reject`, { reason }, { preserveScroll: true })
    setReasonModal({ id: null, action: 'reject' })
    setReason('')
  }

  const handleReschedule = () => {
    if (!rescheduleModal.id || !rescheduleModal.when) return
    router.post(`/dashboard/doctor/appointments/${rescheduleModal.id}/reschedule`, {
      starts_at: rescheduleModal.when.toISOString(),
      reason
    }, { preserveScroll: true })
    setRescheduleModal({ id: null, when: null })
    setReason('')
  }

  const expandedRowRender = (record: Appointment) => (
    <Card
      size="small"
      style={{ margin: '0 12px 12px', background: token.colorBgContainer, borderRadius: 12 }}
      bodyStyle={{ padding: 16 }}
    >
      <Flex vertical gap={10}>
        <Flex gap={8} align="center">
          <Avatar size={32} src={record.patient?.avatarUrl} icon={<IconUser size={16} />} />
          <div>
            <Text strong>{record.patient ? `${record.patient.firstName} ${record.patient.lastName}` : t('Unknown')}</Text>
            {record.patient?.phone && (
              <Text type="secondary" style={{ display: 'block', fontSize: 12 }}>
                {t('Phone')}: {record.patient.phone}
              </Text>
            )}
          </div>
        </Flex>
        <Flex gap={8} align="flex-start">
          <IconNotes size={16} />
          <div>
            <Text strong>{t('Patient message')}</Text>
            <Text style={{ display: 'block', marginTop: 4 }}>
              {record.notes || t('No message provided')}
            </Text>
          </div>
        </Flex>
      </Flex>
    </Card>
  )

  const columns = [
    {
      title: t('Patient'),
      key: 'patient',
      render: (_: unknown, record: Appointment) => (
        <Flex align="center" gap={12}>
          <Avatar src={record.patient?.avatarUrl} icon={<IconUser size={16} />} />
          <div>
            <Text strong>{record.patient ? `${record.patient.firstName} ${record.patient.lastName}` : t('Unknown')}</Text>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', color: token.colorTextSecondary }}>
              <IconNotes size={14} />
              <Text type="secondary" style={{ fontSize: 12 }}>
                {record.appointmentTypeName || t('Consultation')}
              </Text>
            </div>
          </div>
        </Flex>
      )
    },
    {
      title: t('Time'),
      key: 'time',
      render: (_: unknown, record: Appointment) => (
        <Space direction="vertical" size={0}>
          <Flex gap={6} align="center">
            <IconCalendarEvent size={16} />
            <Text>{format(new Date(record.startsAt), 'PP', { locale: dateLocale })}</Text>
          </Flex>
          <Flex gap={6} align="center" style={{ color: token.colorTextSecondary }}>
            <IconClock size={16} />
            <Text>{format(new Date(record.startsAt), 'p', { locale: dateLocale })}</Text>
          </Flex>
        </Space>
      )
    },
    {
      title: t('Mode'),
      key: 'mode',
      render: (_: unknown, record: Appointment) => {
        const mode = record.consultationMode || 'in_person'
        const isVirtual = mode === 'video' || mode === 'telemedicine'
        return (
          <Flex gap={6} align="center">
            {isVirtual ? <IconVideo size={16} /> : <IconMapPin size={16} />}
            <Text>{modeLabel(mode, t)}</Text>
          </Flex>
        )
      }
    },
    {
      title: t('Status'),
      key: 'status',
      render: (_: unknown, record: Appointment) => (
        <Space direction="vertical" size={4}>
          <Tag color={statusColor(record.status)}>{record.status}</Tag>
          {record.status === 'pending' && record.rescheduledFromAppointmentId && (
            <Tag color="blue" style={{ width: 'fit-content' }}>
              {t('Awaiting patient approval')}
            </Tag>
          )}
          {record.status === 'pending' && record.pendingExpiresAt && (
            <Text type="secondary" style={{ fontSize: 12 }}>
              {t('Expires')} {formatDistanceToNow(new Date(record.pendingExpiresAt), { addSuffix: true, locale: dateLocale })}
            </Text>
          )}
        </Space>
      )
    },
    {
      title: t('Actions'),
      key: 'actions',
      render: (_: unknown, record: Appointment) => {
        const isPending = record.status === 'pending'
        const isPatientApprovalPending = isPending && Boolean(record.rescheduledFromAppointmentId)
        const isUpcoming = ['pending', 'confirmed', 'held'].includes(record.status)

        return (
          <Space>
            {isPending && !isPatientApprovalPending && (
              <Popconfirm
                title={t('Approve this appointment?')}
                onConfirm={() => handleApprove(record.id)}
              >
                <Button type="primary" icon={<IconCheck size={16} />}>{t('Approve')}</Button>
              </Popconfirm>
            )}

            {isPatientApprovalPending && (
              <Text type="secondary">{t('Awaiting patient decision')}</Text>
            )}

            {isUpcoming && !isPatientApprovalPending && (
              <Button
                icon={<IconArrowBackUp size={16} />}
                onClick={() => setRescheduleModal({ id: record.id, when: dayjs(record.startsAt) })}
              >
                {t('Reschedule')}
              </Button>
            )}

            {isUpcoming && !isPatientApprovalPending && (
              <Button
                icon={<IconCircleX size={16} />}
                onClick={() => setReasonModal({ id: record.id, action: 'reject' })}
              >
                {t('Reject')}
              </Button>
            )}
          </Space>
        )
      }
    }
  ]

  const cards = [
    {
      label: t('Pending approval'),
      value: counts?.pending ?? 0,
      bg: token.colorWarningBg,
      color: token.colorWarningText
    },
    {
      label: t('Upcoming'),
      value: counts?.upcoming ?? 0,
      bg: token.colorPrimaryBg,
      color: token.colorPrimaryText
    },
    {
      label: t('Completed'),
      value: counts?.completed ?? 0,
      bg: token.colorSuccessBg,
      color: token.colorSuccessText
    },
    {
      label: t('Total'),
      value: counts?.total ?? 0,
      bg: token.colorBgContainer,
      color: token.colorText
    }
  ]

  return (
    <div style={{ maxWidth: 1200, margin: '0 auto', padding: 24 }}>
      <Flex justify="space-between" align="center" wrap="wrap" gap={12} style={{ marginBottom: 16 }}>
        <div>
          <Text type="secondary" style={{ textTransform: 'uppercase', letterSpacing: 0.8, fontWeight: 600 }}>
            {t('Practice')}
          </Text>
          <Title level={2} style={{ margin: 0 }}>
            {t('Appointments')}
          </Title>
          <Text type="secondary">{t('Approve, reschedule, or cancel your visits')}</Text>
        </div>
        <Segmented
          value={filter}
          onChange={(val) => setFilter(String(val))}
          options={[
            { label: t('All'), value: 'all' },
            { label: t('Pending'), value: 'pending' },
            { label: t('Upcoming'), value: 'upcoming' },
            { label: t('Completed'), value: 'completed' },
            { label: t('Cancelled'), value: 'cancelled' }
          ]}
        />
      </Flex>

      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        {cards.map((card) => (
          <Col xs={12} md={6} key={card.label}>
            <Card
              bordered={false}
              style={{
                borderRadius: 14,
                background: card.bg,
                boxShadow: '0 1px 6px rgba(0,0,0,0.04)'
              }}
            >
              <Text type="secondary" style={{ display: 'block', fontSize: 12 }}>
                {card.label}
              </Text>
              <Title level={3} style={{ margin: 0, color: card.color }}>
                {card.value}
              </Title>
            </Card>
          </Col>
        ))}
      </Row>

      <Card bordered={false} style={{ borderRadius: 16, boxShadow: '0 1px 8px rgba(0,0,0,0.05)' }}>
        <Table
          columns={columns}
          dataSource={filteredAppointments}
          rowKey={(row) => row.id}
          expandable={{ expandedRowRender, expandRowByClick: true }}
          pagination={{ pageSize: 8, showSizeChanger: false }}
        />
      </Card>

      {(reasonModal.id) && (
        <Card
          style={{ position: 'fixed', bottom: 24, right: 24, maxWidth: 360, boxShadow: '0 12px 30px rgba(0,0,0,0.16)' }}
          title={t('Reject')}
          extra={<Button type="text" onClick={() => { setReasonModal({ id: null, action: 'reject' }); setReason('') }} icon={<IconX size={16} />} />}
        >
          <Space direction="vertical" style={{ width: '100%' }}>
            <Text type="secondary">{t('Add a short reason for the patient')}</Text>
            <Input.TextArea rows={3} value={reason} onChange={(e) => setReason(e.target.value)} placeholder={t('Example: prefer earlier in the day')} />
            <Button type="primary" danger onClick={handleReject} disabled={!reason.trim()}>{t('Reject')}</Button>
          </Space>
        </Card>
      )}

      {(rescheduleModal.id) && (
        <Card
          style={{ position: 'fixed', bottom: 24, right: 24, maxWidth: 420, boxShadow: '0 12px 30px rgba(0,0,0,0.16)' }}
          title={t('Reschedule')}
          extra={<Button type="text" onClick={() => { setRescheduleModal({ id: null, when: null }); setReason('') }} icon={<IconX size={16} />} />}
        >
          <Space direction="vertical" style={{ width: '100%' }}>
            <Text type="secondary">{t('Pick a new slot to propose')}</Text>
            <DatePicker
              style={{ width: '100%' }}
              value={rescheduleModal.when as Dayjs | null}
              onChange={(date: Dayjs | null) =>
                setRescheduleModal((prev) => ({
                  ...prev,
                  when: date
                    ? prev.when
                      ? date.hour(prev.when.hour()).minute(prev.when.minute())
                      : date
                    : null
                }))
              }
            />
            <TimePicker
              style={{ width: '100%' }}
              value={rescheduleModal.when as Dayjs | null}
              format="HH:mm"
              onChange={(time: Dayjs | null) =>
                setRescheduleModal((prev) => ({
                  ...prev,
                  when: time
                    ? prev.when
                      ? prev.when.hour(time.hour()).minute(time.minute())
                      : time
                    : null
                }))
              }
            />
            <Input.TextArea rows={3} value={reason} onChange={(e) => setReason(e.target.value)} placeholder={t('Add a note for the patient (optional)')} />
            <Button type="primary" onClick={handleReschedule} disabled={!rescheduleModal.when}>
              {t('Send reschedule request')}
            </Button>
          </Space>
        </Card>
      )}
    </div>
  )
}

export default DoctorAppointmentsPage
