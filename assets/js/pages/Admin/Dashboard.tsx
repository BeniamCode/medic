import { Card, Statistic, Row, Col, Alert, Button } from 'antd'
import { UserOutlined, CalendarOutlined, DollarOutlined, ArrowRightOutlined } from '@ant-design/icons'
import { router } from '@inertiajs/react'
import AdminLayout from '@/layouts/AdminLayout'

interface DashboardProps {
    pending_doctors: number
    todays_appointments: number
    todays_revenue: number
}

export default function AdminDashboard({ pending_doctors, todays_appointments, todays_revenue }: DashboardProps) {
    return (
        <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 24 }}>Dashboard</h1>

            {pending_doctors > 0 && (
                <Alert
                    message="Attention Needed"
                    description={`You have ${pending_doctors} doctor application(s) pending review.`}
                    type="warning"
                    showIcon
                    action={
                        <Button
                            size="small"
                            type="text"
                            onClick={() => router.visit('/medic/doctors')}
                            icon={<ArrowRightOutlined />}
                        >
                            Review Now
                        </Button>
                    }
                    style={{ marginBottom: 24 }}
                />
            )}

            <Row gutter={[16, 16]}>
                <Col xs={24} sm={8}>
                    <Card>
                        <Statistic
                            title="Pending Doctors"
                            value={pending_doctors}
                            prefix={<UserOutlined style={{ color: '#1890ff' }} />}
                            valueStyle={{ color: '#1890ff' }}
                        />
                        <div style={{ marginTop: 8, fontSize: 12, color: '#8c8c8c' }}>Waiting for verification</div>
                    </Card>
                </Col>

                <Col xs={24} sm={8}>
                    <Card>
                        <Statistic
                            title="Today's Appointments"
                            value={todays_appointments}
                            prefix={<CalendarOutlined style={{ color: '#52c41a' }} />}
                            valueStyle={{ color: '#52c41a' }}
                        />
                        <div style={{ marginTop: 8, fontSize: 12, color: '#8c8c8c' }}>Across all doctors</div>
                    </Card>
                </Col>

                <Col xs={24} sm={8}>
                    <Card>
                        <Statistic
                            title="Est. Revenue (Today)"
                            value={todays_revenue}
                            prefix={<DollarOutlined style={{ color: '#faad14' }} />}
                            valueStyle={{ color: '#faad14' }}
                            precision={2}
                            suffix="€"
                        />
                        <div style={{ marginTop: 8, fontSize: 12, color: '#8c8c8c' }}>Based on booking fees</div>
                    </Card>
                </Col>
            </Row>
        </div>
    )
}

AdminDashboard.layout = (page: React.ReactElement) => <AdminLayout>{page}</AdminLayout>
