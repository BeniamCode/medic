import { Card as DesktopCard, Space, Typography, Tag, Button as DesktopButton, Row, Col, Modal, Input, Form, Alert, Steps, Divider } from 'antd'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'
import { useMemo, useState } from 'react'
import { useIsMobile } from '@/lib/device'
import { IconClock, IconCheck, IconCalendarEvent } from '@tabler/icons-react'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import { Card as MobileCard, Button as MobileButton, Tag as MobileTag, Dialog, Steps as MobileSteps } from 'antd-mobile'

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

const { Text, Title, Paragraph } = Typography

// =============================================================================
// MOBILE APPOINTMENT DETAIL
// =============================================================================

function MobileAppointmentDetail({ appointment }: { appointment: PageProps['appointment'] }) {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const endsAt = new Date(appointment.endsAt)
  const [submitting, setSubmitting] = useState(false)
  const isPending = appointment.status === 'pending'

  const canAppreciate = useMemo(() => {
    return ['completed', 'confirmed'].includes(appointment.status)
  }, [appointment.status])

  const handleAppreciate = async () => {
    const result = await Dialog.confirm({
      title: t('How was your experience?'),
      content: t('Your appreciation helps other patients find great care.'),
      confirmText: t('Send'),
      cancelText: t('Skip')
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

  const handleWithdraw = async () => {
    const result = await Dialog.confirm({
      title: t('Withdraw request?'),
      content: t('This will cancel your appointment request. You can book a new time afterwards.'),
      confirmText: t('Withdraw'),
      cancelText: t('Keep request')
    })

    if (result) {
      router.post(`/appointments/${appointment.id}/cancel`)
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
        {isPending ? t('Appointment request') : t('Appointment details')}
      </h2>

      <MobileCard style={{ borderRadius: 12 }}>
        {/* Doctor Info */}
        <div style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 600, fontSize: 16 }}>
            Dr. {appointment.doctor.firstName} {appointment.doctor.lastName}
          </div>
          <div style={{ color: '#666', fontSize: 14 }}>{appointment.doctor.specialty}</div>
        </div>

        {/* Status Hero for Pending */}
        {isPending && (
          <div style={{
            backgroundColor: '#fffbe6',
            border: '1px solid #ffe58f',
            borderRadius: 8,
            padding: 16,
            marginBottom: 16,
            textAlign: 'center'
          }}>
            <div style={{ fontSize: 24, marginBottom: 8 }}>⏳</div>
            <div style={{ fontWeight: 600, fontSize: 16, color: '#ad6800' }}>
              {t('Request sent — awaiting confirmation')}
            </div>
            <div style={{ color: '#ad8b00', fontSize: 13, marginTop: 4 }}>
              {t("We'll notify you when the doctor approves or suggests a new time.")}
            </div>
          </div>
        )}

        {/* Progress Stepper */}
        {isPending && (
          <div style={{ marginBottom: 16 }}>
            <MobileSteps
              current={0}
              items={[
                { title: t('Requested'), icon: <IconCheck size={16} /> },
                { title: t('Confirmed') },
                { title: t('Visit') }
              ]}
            />
          </div>
        )}

        {/* Confirmed Status */}
        {!isPending && (
          <div style={{ marginBottom: 12 }}>
            <MobileTag color={statusColor()}>{appointment.status}</MobileTag>
          </div>
        )}

        {/* Date/Time */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginTop: 8 }}>
          <div>
            <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>
              {isPending ? t('Requested date') : t('Date')}
            </div>
            <div style={{ fontWeight: 500 }}>{format(startsAt, 'PPP')}</div>
            {isPending && <div style={{ color: '#ad8b00', fontSize: 11 }}>{t('Not confirmed yet')}</div>}
          </div>
          <div>
            <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>
              {isPending ? t('Requested time') : t('Time')}
            </div>
            <div style={{ fontWeight: 500 }}>{format(startsAt, 'p')} - {format(endsAt, 'p')}</div>
            {isPending && <div style={{ color: '#ad8b00', fontSize: 11 }}>{t('Not confirmed yet')}</div>}
          </div>
        </div>

        {appointment.notes && (
          <div style={{ marginTop: 16 }}>
            <div style={{ color: '#999', fontSize: 12, marginBottom: 4 }}>{t('Notes')}</div>
            <div>{appointment.notes}</div>
          </div>
        )}

        {/* What happens next - for pending */}
        {isPending && (
          <div style={{
            marginTop: 16,
            padding: 12,
            backgroundColor: '#f5f5f5',
            borderRadius: 8
          }}>
            <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 8 }}>{t('What happens next')}</div>
            <ul style={{ margin: 0, paddingLeft: 16, fontSize: 13, color: '#666' }}>
              <li>{t("We'll notify you when approved")}</li>
              <li>{t('Typical response time: 2–24 hours')}</li>
              <li>{t('If declined, you can pick another slot')}</li>
            </ul>
          </div>
        )}

        {/* Actions */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 16, paddingTop: 16, borderTop: '1px solid #f0f0f0' }}>
          {isPending ? (
            <>
              <MobileButton block color="primary" style={{ '--border-radius': '8px' }}>
                {t('Change requested time')}
              </MobileButton>
              <div style={{ fontSize: 11, color: '#999', textAlign: 'center', marginTop: -4 }}>
                {t('Changing the time will require re-approval')}
              </div>
              <MobileButton block color="danger" fill="outline" onClick={handleWithdraw} style={{ '--border-radius': '8px' }}>
                {t('Withdraw request')}
              </MobileButton>
            </>
          ) : (
            <>
              <MobileButton block color="primary" style={{ '--border-radius': '8px' }}>
                {t('Reschedule')}
              </MobileButton>
              <MobileButton block color="danger" fill="outline" style={{ '--border-radius': '8px' }}>
                {t('Cancel appointment')}
              </MobileButton>
              {canAppreciate && (
                <MobileButton
                  block
                  fill="outline"
                  loading={submitting}
                  onClick={handleAppreciate}
                  style={{ '--border-radius': '8px' }}
                >
                  💙 {t('Express appreciation')}
                </MobileButton>
              )}
            </>
          )}
        </div>
      </MobileCard>
    </div>
  )
}

// =============================================================================
// DESKTOP APPOINTMENT DETAIL
// =============================================================================

function DesktopAppointmentDetail({ appointment }: { appointment: PageProps['appointment'] }) {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const endsAt = new Date(appointment.endsAt)
  const [appreciateOpen, setAppreciateOpen] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const isPending = appointment.status === 'pending'

  const canAppreciate = useMemo(() => {
    return ['completed', 'confirmed'].includes(appointment.status)
  }, [appointment.status])

  const handleWithdraw = () => {
    Modal.confirm({
      title: t('Withdraw request?'),
      content: t('This will cancel your appointment request. You can book a new time afterwards.'),
      okText: t('Withdraw'),
      cancelText: t('Keep request'),
      okButtonProps: { danger: true },
      onOk: () => {
        router.post(`/appointments/${appointment.id}/cancel`)
      }
    })
  }

  const getTagColor = () => {
    switch (appointment.status) {
      case 'confirmed': return 'green'
      case 'pending': return 'orange'
      case 'cancelled': return 'red'
      case 'completed': return 'blue'
      default: return 'default'
    }
  }

  return (
    <Space direction="vertical" size="large" style={{ width: '100%' }}>
      <Title level={3} style={{ marginBottom: 0 }}>
        {isPending ? t('Appointment request') : t('Appointment details')}
      </Title>

      <DesktopCard bordered style={{ borderRadius: 12 }}>
        <Space direction="vertical" size="middle" style={{ width: '100%' }}>
          {/* Doctor Info Header */}
          <div>
            <Text strong style={{ fontSize: 16 }}>
              Dr. {appointment.doctor.firstName} {appointment.doctor.lastName}
            </Text>
            <Text type="secondary" style={{ display: 'block' }}>
              {appointment.doctor.specialty}
            </Text>
          </div>

          {/* Status Hero for Pending */}
          {isPending && (
            <div style={{
              backgroundColor: '#fffbe6',
              border: '1px solid #ffe58f',
              borderRadius: 8,
              padding: 20,
              textAlign: 'center'
            }}>
              <div style={{ fontSize: 32, marginBottom: 8 }}>⏳</div>
              <Title level={4} style={{ margin: 0, color: '#ad6800' }}>
                {t('Request sent — awaiting confirmation')}
              </Title>
              <Paragraph type="secondary" style={{ marginBottom: 0, marginTop: 8 }}>
                {t("We'll notify you when the doctor approves or suggests a new time.")}
              </Paragraph>
            </div>
          )}

          {/* Progress Stepper for Pending */}
          {isPending && (
            <Steps
              size="small"
              current={0}
              items={[
                { title: t('Requested'), icon: <IconCheck size={16} /> },
                { title: t('Confirmed'), icon: <IconClock size={16} /> },
                { title: t('Visit'), icon: <IconCalendarEvent size={16} /> }
              ]}
            />
          )}

          {/* Confirmed/Other Status Tag */}
          {!isPending && (
            <div>
              <Tag color={getTagColor()} style={{ fontSize: 14, padding: '4px 12px' }}>
                {appointment.status}
              </Tag>
            </div>
          )}

          <Divider style={{ margin: '8px 0' }} />

          {/* Date/Time Info */}
          <Row gutter={24}>
            <Col xs={24} sm={12}>
              <Text type="secondary">{isPending ? t('Requested date') : t('Date')}</Text>
              <Text strong style={{ display: 'block' }}>{format(startsAt, 'PPPP')}</Text>
              {isPending && (
                <Text style={{ fontSize: 12, color: '#ad8b00' }}>{t('Not confirmed yet')}</Text>
              )}
            </Col>
            <Col xs={24} sm={12}>
              <Text type="secondary">{isPending ? t('Requested time') : t('Time')}</Text>
              <Text strong style={{ display: 'block' }}>{format(startsAt, 'p')} - {format(endsAt, 'p')}</Text>
              {isPending && (
                <Text style={{ fontSize: 12, color: '#ad8b00' }}>{t('Not confirmed yet')}</Text>
              )}
            </Col>
          </Row>

          {/* Notes */}
          {appointment.notes && (
            <div>
              <Text type="secondary">{t('Notes')}</Text>
              <Paragraph style={{ marginBottom: 0 }}>{appointment.notes}</Paragraph>
            </div>
          )}

          {/* What happens next - for pending */}
          {isPending && (
            <>
              <Divider style={{ margin: '8px 0' }} />
              <div style={{
                padding: 16,
                backgroundColor: '#fafafa',
                borderRadius: 8,
                border: '1px solid #f0f0f0'
              }}>
                <Text strong style={{ display: 'block', marginBottom: 8 }}>{t('What happens next')}</Text>
                <ul style={{ margin: 0, paddingLeft: 20, color: '#666' }}>
                  <li>{t("We'll notify you when approved")}</li>
                  <li>{t('Typical response time: 2–24 hours')}</li>
                  <li>{t('If declined, you can pick another slot')}</li>
                </ul>
              </div>
            </>
          )}

          <Divider style={{ margin: '8px 0' }} />

          {/* Actions */}
          {isPending ? (
            <Space direction="vertical" size="small" style={{ width: '100%' }}>
              <Space size="small">
                <DesktopButton type="primary">{t('Change requested time')}</DesktopButton>
                <DesktopButton danger type="default" onClick={handleWithdraw}>
                  {t('Withdraw request')}
                </DesktopButton>
              </Space>
              <Text type="secondary" style={{ fontSize: 12 }}>
                {t('Changing the time will require re-approval')}
              </Text>
            </Space>
          ) : (
            <Space size="small">
              <DesktopButton type="primary">{t('Reschedule')}</DesktopButton>
              <DesktopButton danger type="default">{t('Cancel appointment')}</DesktopButton>
              {canAppreciate && (
                <DesktopButton
                  type="default"
                  onClick={() => setAppreciateOpen(true)}
                >
                  💙 {t('Express appreciation')}
                </DesktopButton>
              )}
            </Space>
          )}
        </Space>
      </DesktopCard>

      {/* Appreciation Modal */}
      <Modal
        open={appreciateOpen}
        title={t('How was your experience?')}
        okText={t('Send appreciation')}
        cancelText={t('Skip')}
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
          <Paragraph style={{ marginBottom: 0 }}>
            {t('Your appreciation is anonymous and helps other patients find great care.')}
          </Paragraph>

          <Form layout="vertical">
            <Form.Item label={t('Optional thank-you note (max 80 characters)')}>
              <Input.TextArea
                id="appreciation-note"
                maxLength={80}
                placeholder={t('E.g. Very kind and caring.')}
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
