import { Card, Space, Typography, Tag, Button, Row, Col } from 'antd'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

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

const AppointmentDetailPage = ({ app, auth, appointment }: PageProps) => {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const endsAt = new Date(appointment.endsAt)

  return (
    <PublicLayout app={app} auth={auth}>
      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        <Typography.Title level={3}>{t('appointment.title', 'Appointment details')}</Typography.Title>

        <Card bordered style={{ borderRadius: 12 }}>
          <Space direction="vertical" size="middle" style={{ width: '100%' }}>
            <Row justify="space-between" align="middle">
              <Col>
                <Typography.Text strong>
                  Dr. {appointment.doctor.firstName} {appointment.doctor.lastName}
                </Typography.Text>
                <Typography.Text type="secondary" style={{ display: 'block' }}>
                  {appointment.doctor.specialty}
                </Typography.Text>
              </Col>
              <Col>
                <Tag color="blue">{appointment.status}</Tag>
              </Col>
            </Row>

            <Row gutter={24}>
              <Col xs={24} sm={12}>
                <Typography.Text type="secondary">
                  {t('appointment.labels.date', 'Date')}
                </Typography.Text>
                <Typography.Text strong style={{ display: 'block' }}>
                  {format(startsAt, 'PPPP')}
                </Typography.Text>
              </Col>
              <Col xs={24} sm={12}>
                <Typography.Text type="secondary">
                  {t('appointment.labels.time', 'Time')}
                </Typography.Text>
                <Typography.Text strong style={{ display: 'block' }}>
                  {format(startsAt, 'p')} - {format(endsAt, 'p')}
                </Typography.Text>
              </Col>
            </Row>

            {appointment.notes && (
              <div>
                <Typography.Text type="secondary">
                  {t('appointment.labels.notes', 'Notes')}
                </Typography.Text>
                <Typography.Paragraph style={{ marginBottom: 0 }}>{appointment.notes}</Typography.Paragraph>
              </div>
            )}

            <Space size="small">
              <Button type="primary">{t('appointment.cta.reschedule', 'Reschedule')}</Button>
              <Button danger type="default">{t('appointment.cta.cancel', 'Cancel appointment')}</Button>
            </Space>
          </Space>
        </Card>
      </Space>
    </PublicLayout>
  )
}

export default AppointmentDetailPage
