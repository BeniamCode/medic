import { Card as DesktopCard, Space, Typography, Tag, Button as DesktopButton, Row, Col, Modal, Input, Form } from 'antd'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'
import { useMemo, useState } from 'react'
import { useIsMobile } from '@/lib/device'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import { Card as MobileCard, Button as MobileButton, Tag as MobileTag, Dialog, TextArea } from 'antd-mobile'

type PageProps = AppPageProps<{
  appointment: {
    id: string
    startsAt: string
    endsAt: string
    status: string
    notes?: string | null
    doctor: {
      id: string
      firstName: string
      lastName: string
      specialty?: string | null
    }
    patient: {
      id: string
      firstName: string
      lastName: string
    }
  }
}>

const { Text } = Typography

// =============================================================================
// MOBILE APPOINTMENT DETAIL
// =============================================================================

function MobileAppointmentDetail({ appointment }: { appointment: PageProps['appointment'] }) {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const endsAt = new Date(appointment.endsAt)
  const [submitting, setSubmitting] = useState(false)

  const canAppreciate = useMemo(() => {
    return ['completed', 'confirmed'].includes(appointment.status)
  }, [appointment.status])

  const handleAppreciate = async () => {
    const result = await Dialog.confirm({
      title: t('appointment.appreciate.title', 'How was your experience?'),
      content: t('appointment.appreciate.body', 'Your appreciation helps other patients find great care.'),
      confirmText: t('appointment.appreciate.submit', 'Send'),
      cancelText: t('appointment.appreciate.skip', 'Skip')
    })

    if (result) {
      setSubmitting(true)
      router.post(
        `/appointments/${appointment.id}/appreciate`,
        { note_text: '' },
        {
          onFinish: () => setSubmitting(false)
        }
      )
    }
  }

  const statusColor = () => {
    switch (appointment.status) {
      case 'confirmed': return 'success'
      case 'pending': return 'warning'
      case 'cancelled': return 'danger'
      default: return 'default'
    }
  }

  return (
    <div style={{ padding: 16, paddingBottom: 80 }}>
      <h2 style={{ fontSize: 20, fontWeight: 700, margin: '0 0 16px' }}>
        {t('appointment.title', 'Appointment details')}
      </h2>

      <MobileCard style={{ borderRadius: 12 }}>
        <div style={{ marginBottom: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
            <div>
              <div style={{ fontWeight: 600, fontSize: 16 }}>
                Dr. {appointment.doctor.firstName} {appointment.doctor.lastName}
              </div>
              <div style={{ color: '#666', fontSize: 14 }}>{appointment.doctor.specialty}</div>
            </div>
            <MobileTag color={statusColor()}>{appointment.status}</MobileTag>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 16 }}>
            <div>
              <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>{t('appointment.labels.date', 'Date')}</div>
              <div style={{ fontWeight: 500 }}>{format(startsAt, 'PPP')}</div>
            </div>
            <div>
              <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>{t('appointment.labels.time', 'Time')}</div>
              <div style={{ fontWeight: 500 }}>{format(startsAt, 'p')} - {format(endsAt, 'p')}</div>
            </div>
          </div>

          {appointment.notes && (
            <div style={{ marginTop: 16 }}>
              <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>{t('appointment.labels.notes', 'Notes')}</div>
              <div>{appointment.notes}</div>
            </div>
          )}
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 16, paddingTop: 16, borderTop: '1px solid #f0f0f0' }}>
          <MobileButton block color="primary" style={{ '--border-radius': '8px' }}>
            {t('appointment.cta.reschedule', 'Reschedule')}
          </MobileButton>
          <MobileButton block color="danger" fill="outline" style={{ '--border-radius': '8px' }}>
            {t('appointment.cta.cancel', 'Cancel appointment')}
          </MobileButton>
          {canAppreciate && (
            <MobileButton
              block
              fill="outline"
              loading={submitting}
              onClick={handleAppreciate}
              style={{ '--border-radius': '8px' }}
            >
              💙 {t('appointment.cta.appreciate', 'Express appreciation')}
            </MobileButton>
          )}
        </div>
      </MobileCard>
    </div>
  )
}

// =============================================================================
// DESKTOP APPOINTMENT DETAIL (Original)
// =============================================================================

function DesktopAppointmentDetail({ appointment }: { appointment: PageProps['appointment'] }) {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const endsAt = new Date(appointment.endsAt)
  const [appreciateOpen, setAppreciateOpen] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  const canAppreciate = useMemo(() => {
    return ['completed', 'confirmed'].includes(appointment.status)
  }, [appointment.status])

  return (
    <Space direction="vertical" size="large" style={{ width: '100%' }}>
      <Typography.Title level={3}>{t('appointment.title', 'Appointment details')}</Typography.Title>

      <DesktopCard bordered style={{ borderRadius: 12 }}>
        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
          <Row justify="space-between" align="middle">
            <Col>
              <Text strong>
                Dr. {appointment.doctor.firstName} {appointment.doctor.lastName}
              </Text>
              <Text type="secondary" style={{ display: 'block' }}>
                {appointment.doctor.specialty}
              </Text>
            </Col>
            <Col>
              <Tag color="blue">{appointment.status}</Tag>
            </Col>
          </Row>

          <Row gutter={24}>
            <Col xs={24} sm={12}>
              <Text type="secondary">{t('appointment.labels.date', 'Date')}</Text>
              <Text strong style={{ display: 'block' }}>{format(startsAt, 'PPPP')}</Text>
            </Col>
            <Col xs={24} sm={12}>
              <Text type="secondary">{t('appointment.labels.time', 'Time')}</Text>
              <Text strong style={{ display: 'block' }}>{format(startsAt, 'p')} - {format(endsAt, 'p')}</Text>
            </Col>
          </Row>

          {appointment.notes && (
            <div>
              <Text type="secondary">{t('appointment.labels.notes', 'Notes')}</Text>
              <Typography.Paragraph style={{ marginBottom: 0 }}>{appointment.notes}</Typography.Paragraph>
            </div>
          )}

          <Space size="small">
            <DesktopButton type="primary">{t('appointment.cta.reschedule', 'Reschedule')}</DesktopButton>
            <DesktopButton danger type="default">{t('appointment.cta.cancel', 'Cancel appointment')}</DesktopButton>
            <DesktopButton
              type="default"
              disabled={!canAppreciate}
              onClick={() => setAppreciateOpen(true)}
            >
              💙 {t('appointment.cta.appreciate', 'Express appreciation')}
            </DesktopButton>
          </Space>
        </Space>
      </DesktopCard>

      <Modal
        open={appreciateOpen}
        title={t('appointment.appreciate.title', 'How was your experience?')}
        okText={t('appointment.appreciate.submit', 'Send appreciation')}
        cancelText={t('appointment.appreciate.skip', 'Skip')}
        confirmLoading={submitting}
        onCancel={() => setAppreciateOpen(false)}
        onOk={() => {
          const note = (document.getElementById('appreciation-note') as HTMLTextAreaElement | null)?.value
          router.post(
            `/appointments/${appointment.id}/appreciate`,
            { note_text: note },
            {
              onStart: () => setSubmitting(true),
              onFinish: () => {
                setSubmitting(false)
                setAppreciateOpen(false)
              }
            }
          )
        }}
      >
        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
          <Typography.Paragraph style={{ marginBottom: 0 }}>
            {t('appointment.appreciate.body', 'Your appreciation is anonymous and helps other patients find great care.')}
          </Typography.Paragraph>

          <Form layout="vertical">
            <Form.Item label={t('appointment.appreciate.noteLabel', 'Optional thank-you note (max 80 characters)')}>
              <Input.TextArea
                id="appreciation-note"
                maxLength={80}
                placeholder={t('appointment.appreciate.placeholder', 'E.g. Very kind and caring.')}
                autoSize={{ minRows: 2, maxRows: 4 }}
              />
            </Form.Item>
          </Form>
        </Space>
      </Modal>
    </Space>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

const AppointmentDetailPage = ({ app, auth, appointment }: PageProps) => {
  const isMobile = useIsMobile()

  if (isMobile) {
    return <MobileAppointmentDetail appointment={appointment} />
  }

  return <DesktopAppointmentDetail appointment={appointment} />
}

export default AppointmentDetailPage
