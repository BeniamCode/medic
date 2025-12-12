import {
  Button,
  Card,
  Col,
  Row,
  Typography,
  Select,
  TimePicker,
  Modal,
  Space,
  Table,
  Form,
  DatePicker,
  Tag,
  Flex,
  Popconfirm,
  Empty
} from 'antd'
import {
  IconClock,
  IconPlus,
  IconTrash,
  IconEdit
} from '@tabler/icons-react'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import { useState } from 'react'
import dayjs, { Dayjs } from 'dayjs'
import type { AppPageProps } from '@/types/app'

const { Text } = Typography
const { RangePicker } = TimePicker
const { Option } = Select

type AvailabilityRule = {
  id?: string
  day_of_week: number
  start_time: string
  end_time: string
  visit_type: 'in-person' | 'video'
}

type Appointment = {
  id: string
  patient: {
    first_name: string
    last_name: string
    avatar_url?: string
  }
  starts_at: string
  type: 'in-person' | 'video'
  status: string
}

type PageProps = AppPageProps<{
  availabilityRules: AvailabilityRule[]
  upcomingAppointments: Appointment[]
  blockedDates: string[]
}>

const DoctorSchedule = ({ availabilityRules, upcomingAppointments, blockedDates }: PageProps) => {
  const { t } = useTranslation('default')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingRule, setEditingRule] = useState<AvailabilityRule | null>(null)
  const [form] = Form.useForm()

  const [activeTab, setActiveTab] = useState<string>('1') // 1 corresponds to Monday

  const days = [
    { value: '1', label: t('days.monday', 'Monday') },
    { value: '2', label: t('days.tuesday', 'Tuesday') },
    { value: '3', label: t('days.wednesday', 'Wednesday') },
    { value: '4', label: t('days.thursday', 'Thursday') },
    { value: '5', label: t('days.friday', 'Friday') },
    { value: '6', label: t('days.saturday', 'Saturday') },
    { value: '0', label: t('days.sunday', 'Sunday') }
  ]

  const handleEditRule = (rule: AvailabilityRule) => {
    setEditingRule(rule)
    form.setFieldsValue({
      visit_type: rule.visit_type,
      time_range: [
        dayjs(rule.start_time, 'HH:mm:ss'),
        dayjs(rule.end_time, 'HH:mm:ss')
      ]
    })
    setIsModalOpen(true)
  }

  const handleDeleteRule = (ruleId: string) => {
    router.delete(`/doctor/schedule/rules/${ruleId}`, {
      onSuccess: () => {
        // notification.success({ message: t('schedule.rule_deleted') })
      }
    })
  }

  const handleSaveRule = (values: any) => {
    const payload = {
      day_of_week: parseInt(activeTab),
      visit_type: values.visit_type,
      start_time: values.time_range[0].format('HH:mm:ss'),
      end_time: values.time_range[1].format('HH:mm:ss')
    }

    if (editingRule?.id) {
      router.put(`/doctor/schedule/rules/${editingRule.id}`, payload, {
        onSuccess: () => setIsModalOpen(false)
      })
    } else {
      router.post('/doctor/schedule/rules', payload, {
        onSuccess: () => setIsModalOpen(false)
      })
    }
  }

  const handleBlockDate = (date: Dayjs) => {
    if (!date) return
    router.post('/doctor/schedule/block-date', { date: date.format('YYYY-MM-DD') })
  }

  const handleUnblockDate = (dateStr: string) => {
    router.delete('/doctor/schedule/block-date', { data: { date: dateStr } })
  }

  const columns = [
    {
      title: t('schedule.time_slot', 'Time Slot'),
      key: 'time',
      render: (_: any, record: AvailabilityRule) => (
        <Space>
          <IconClock size={16} />
          <Text>
            {dayjs(record.start_time, 'HH:mm:ss').format('h:mm A')} - {dayjs(record.end_time, 'HH:mm:ss').format('h:mm A')}
          </Text>
        </Space>
      )
    },
    {
      title: t('schedule.type', 'Type'),
      dataIndex: 'visit_type',
      key: 'type',
      render: (type: string) => (
        <Tag color={type === 'video' ? 'blue' : 'green'}>
          {type === 'video' ? t('schedule.video', 'Video') : t('schedule.in_person', 'In-Person')}
        </Tag>
      )
    },
    {
      title: t('common.actions', 'Actions'),
      key: 'actions',
      render: (_: any, record: AvailabilityRule) => (
        <Space>
          <Button type="text" icon={<IconEdit size={16} />} onClick={() => handleEditRule(record)} />
          <Popconfirm title={t('common.are_you_sure')} onConfirm={() => handleDeleteRule(record.id!)}>
            <Button type="text" danger icon={<IconTrash size={16} />} />
          </Popconfirm>
        </Space>
      )
    }
  ]

  const currentDayRules = availabilityRules.filter((r: AvailabilityRule) => r.day_of_week === parseInt(activeTab))

  return (
    <div style={{ padding: 24, paddingBottom: 80 }}>
      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Card
            title={t('schedule.weekly_hours', 'Weekly Hours')}
            extra={<Button type="primary" icon={<IconPlus size={16} />} onClick={() => { setEditingRule(null); form.resetFields(); setIsModalOpen(true) }}>{t('schedule.add_slot', 'Add Slot')}</Button>}
          >
            <div style={{ marginBottom: 16 }}>
              <Space wrap>
                {days.map(day => (
                  <Button
                    key={day.value}
                    type={activeTab === day.value ? 'primary' : 'default'}
                    onClick={() => setActiveTab(day.value)}
                    shape="round"
                  >
                    {day.label}
                  </Button>
                ))}
              </Space>
            </div>

            <Table
              dataSource={currentDayRules}
              columns={columns}
              rowKey="id"
              pagination={false}
              locale={{ emptyText: t('schedule.no_slots', 'No availability slots for this day') }}
            />
          </Card>

          <Card title={t('schedule.time_off', 'Time Off')} style={{ marginTop: 24 }}>
            <Space direction="vertical" style={{ width: '100%' }}>
              <Text type="secondary">{t('schedule.block_dates_desc', 'Block specific dates when you are unavailable.')}</Text>
              <DatePicker
                style={{ width: '100%' }}
                onChange={handleBlockDate}
                placeholder={t('schedule.select_date_to_block', 'Select date to block')}
                disabledDate={(current: Dayjs) => current && current < dayjs().endOf('day')}
              />
              <div style={{ marginTop: 16 }}>
                {blockedDates.length > 0 && <Text strong>{t('schedule.blocked_days', 'Blocked Days:')}</Text>}
                <Space size={[8, 16]} wrap style={{ marginTop: 8 }}>
                  {blockedDates.map((date: string) => (
                    <Tag
                      key={date}
                      closeIcon={<IconTrash size={12} />}
                      onClose={() => handleUnblockDate(date)}
                      color="red"
                    >
                      {dayjs(date).format('MMM D, YYYY')}
                    </Tag>
                  ))}
                </Space>
              </div>
            </Space>
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card title={t('schedule.upcoming', 'Upcoming Appointments')}>
            {upcomingAppointments.length > 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {upcomingAppointments.map((appt: Appointment) => (
                  <Card key={appt.id} size="small" type="inner">
                    <Flex justify="space-between" align="start">
                      <Space>
                        <div
                          style={{
                            width: 32,
                            height: 32,
                            borderRadius: '50%',
                            backgroundColor: '#f1f5f9',
                            overflow: 'hidden'
                          }}
                        >
                          <img src={appt.patient.avatar_url || `https://ui-avatars.com/api/?name=${appt.patient.first_name}+${appt.patient.last_name}`} alt="Patient" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        </div>
                        <div>
                          <Text strong>{appt.patient.first_name} {appt.patient.last_name}</Text>
                          <div style={{ fontSize: 12, color: '#64748b' }}>
                            {dayjs(appt.starts_at).format('MMM D, h:mm A')}
                          </div>
                        </div>
                      </Space>
                      <Tag>{appt.type === 'video' ? 'Video' : 'In-Person'}</Tag>
                    </Flex>
                  </Card>
                ))}
              </div>
            ) : (
              <Empty description={t('schedule.no_upcoming', 'No upcoming appointments')} />
            )}
            <Button block type="dashed" style={{ marginTop: 16 }} href="/doctor/appointments">
              {t('schedule.view_all', 'View All Appointments')}
            </Button>
          </Card>
        </Col>
      </Row>

      <Modal
        title={editingRule ? t('schedule.edit_slot', 'Edit Availability Slot') : t('schedule.add_slot', 'Add Availability Slot')}
        open={isModalOpen}
        onCancel={() => setIsModalOpen(false)}
        footer={null}
      >
        <Form
          form={form}
          layout="vertical"
          onFinish={handleSaveRule}
          initialValues={{ visit_type: 'in-person' }}
        >
          <Form.Item
            name="visit_type"
            label={t('schedule.visit_type', 'Visit Type')}
            rules={[{ required: true }]}
          >
            <Select>
              <Option value="in-person">{t('schedule.in_person', 'In-Person')}</Option>
              <Option value="video">{t('schedule.video', 'Video')}</Option>
            </Select>
          </Form.Item>

          <Form.Item
            name="time_range"
            label={t('schedule.time_range', 'Time Range')}
            rules={[{ required: true }]}
          >
            <RangePicker format="h:mm A" minuteStep={15} style={{ width: '100%' }} />
          </Form.Item>

          <Flex justify="end" gap="small" style={{ marginTop: 24 }}>
            <Button onClick={() => setIsModalOpen(false)}>
              {t('common.cancel', 'Cancel')}
            </Button>
            <Button type="primary" htmlType="submit">
              {t('common.save', 'Save')}
            </Button>
          </Flex>
        </Form>
      </Modal>
    </div>
  )
}

export default DoctorSchedule
