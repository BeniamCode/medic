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
  Empty,
  Switch,
  InputNumber,
  Input,
  Divider,
  message,
  Steps,
  Radio
} from 'antd'
import {
  IconClock,
  IconPlus,
  IconTrash,
  IconEdit,
  IconCalendarEvent,
  IconUser,
  IconVideo,
  IconPhone
} from '@tabler/icons-react'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import { useState, useMemo } from 'react'
import dayjs, { Dayjs } from 'dayjs'
import utc from 'dayjs/plugin/utc'
import timezone from 'dayjs/plugin/timezone'
import { useForm, useFieldArray, Controller } from 'react-hook-form'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import axios from 'axios'
import type { AppPageProps } from '@/types/app'

dayjs.extend(utc)
dayjs.extend(timezone)

const { Text, Title } = Typography
const { RangePicker } = TimePicker
const { Option } = Select

// --- Types ---

type Break = {
  breakStartLocal: string
  breakEndLocal: string
  label?: string
}

type Window = {
  workStartLocal: string
  workEndLocal: string
  slotIntervalMinutes: number
  breaks: Break[]
  effectiveFrom?: string | null
  effectiveTo?: string | null
}

type DayConfig = {
  dayOfWeek: number
  enabled: boolean
  windows: Window[]
}

type Scope = {
  appointmentTypeId?: string | null
  doctorLocationId?: string | null
  locationRoomId?: string | null
  consultationMode?: 'in_person' | 'video' | 'phone' | null
  timezone: string
}

type AddSlotFormValues = {
  scope: Scope
  days: DayConfig[]
  replaceMode: 'replace_selected_days' | 'append'
}

type AvailabilityRule = {
  id: string
  day_of_week: number
  start_time: string
  end_time: string
  visit_type: 'in-person' | 'video'
  breaks?: { break_start_local: string; break_end_local: string }[]
}

type ScheduleException = {
  id: string
  start_date: string
  end_date: string
  reason: string
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
  exceptions: ScheduleException[]
  doctor: { id: string; timezone?: string }
}>

const DEFAULT_TIMEZONE = "Europe/Athens"

const INITIAL_FORM_VALUES: AddSlotFormValues = {
  scope: {
    timezone: DEFAULT_TIMEZONE,
    consultationMode: 'in_person'
  },
  days: [1, 2, 3, 4, 5, 6, 7].map((d) => ({
    dayOfWeek: d,
    enabled: d <= 5, // Enable Mon-Fri by default
    windows: [{
      workStartLocal: '09:00',
      workEndLocal: '17:00',
      slotIntervalMinutes: 30,
      breaks: []
    }]
  })),
  replaceMode: 'replace_selected_days'
}

const DoctorSchedule = ({
  availabilityRules = [],
  upcomingAppointments = [],
  exceptions = [],
  doctor
}: PageProps) => {
  /* Add form instance */
  const [form] = Form.useForm()
  const exceptionType = Form.useWatch('type', form)
  const isRange = exceptionType === 'range'

  const { t } = useTranslation('default')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isTimeOffModalOpen, setIsTimeOffModalOpen] = useState(false)
  const [activeTab, setActiveTab] = useState<string>('1') // 1=Monday
  const [previewData, setPreviewData] = useState<any>(null)
  const queryClient = useQueryClient()

  // --- React Hook Form ---
  const { control, handleSubmit, watch, reset, setValue } = useForm<AddSlotFormValues>({
    defaultValues: INITIAL_FORM_VALUES
  })

  const { fields: dayFields } = useFieldArray({
    control,
    name: "days"
  })

  // Watch for changes to trigger preview (debounce could be added here)
  const formValues = watch()

  // --- Mutations ---

  const previewMutation = useMutation({
    mutationFn: async (values: AddSlotFormValues) => {
      // Calculate next week for preview
      const start = dayjs().startOf('week').add(1, 'week').format('YYYY-MM-DD')
      const end = dayjs().startOf('week').add(1, 'week').endOf('week').format('YYYY-MM-DD')

      const payload = {
        ...values,
        dateRange: { start, end }
      }
      const res = await axios.post('/api/doctor/schedule/preview', payload)
      return res.data
    },
    onSuccess: (data) => {
      setPreviewData(data)
    }
  })

  const saveMutation = useMutation({
    mutationFn: async (values: AddSlotFormValues) => {
      const res = await axios.post('/api/doctor/schedule/rules/bulk_upsert', values)
      return res.data
    },
    onSuccess: () => {
      message.success(t('schedule.saved_successfully', 'Schedule saved successfully'))
      setIsModalOpen(false)
      router.reload({ only: ['availabilityRules'] })
    },
    onError: (err) => {
      message.error(t('schedule.save_failed', 'Failed to save schedule'))
      console.error(err)
    }
  })

  const handlePreview = () => {
    previewMutation.mutate(formValues)
  }

  const onSubmit = (data: AddSlotFormValues) => {
    saveMutation.mutate(data)
  }

  const handleCreateException = (values: any) => {
    const { range, date, reason, type } = values
    let startsAt, endsAt

    if (type === 'range' && range && range.length === 2) {
      startsAt = range[0].startOf('day').toISOString()
      endsAt = range[1].endOf('day').toISOString()
    } else if (type === 'single' && date) {
      startsAt = date.startOf('day').toISOString()
      endsAt = date.endOf('day').toISOString()
    } else {
      return
    }

    router.post('/doctor/schedule/exceptions', {
      exception: { starts_at: startsAt, ends_at: endsAt, reason }
    }, {
      onSuccess: () => {
        setIsTimeOffModalOpen(false)
        form.resetFields()
      }
    })
  }

  const handleDeleteException = (id: string) => {
    router.delete(`/doctor/schedule/exceptions/${id}`)
  }

  const daysOptions = [
    { value: 1, label: t('days.monday', 'Mon') },
    { value: 2, label: t('days.tuesday', 'Tue') },
    { value: 3, label: t('days.wednesday', 'Wed') },
    { value: 4, label: t('days.thursday', 'Thu') },
    { value: 5, label: t('days.friday', 'Fri') },
    { value: 6, label: t('days.saturday', 'Sat') },
    { value: 7, label: t('days.sunday', 'Sun') }
  ]

  // Filter rules for the active tab (Weekly View)
  const currentDayRules = availabilityRules.filter((r: AvailabilityRule) => r.day_of_week === parseInt(activeTab))

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
      title: t('schedule.mode', 'Mode'),
      dataIndex: 'visit_type', // legacy field map, or scope_consultation_mode
      render: (val: string) => <Tag>{val || 'In-Person'}</Tag>
    },
    {
      title: t('common.actions', 'Actions'),
      key: 'actions',
      render: (_: any, record: AvailabilityRule) => (
        <Popconfirm title={t('common.are_you_sure')} onConfirm={() => router.delete(`/doctor/schedule/${record.id}`)}>
          <Button type="text" danger icon={<IconTrash size={16} />} />
        </Popconfirm>
      )
    }
  ]

  return (
    <div style={{ padding: 24, paddingBottom: 80 }}>
      {/* Header */}
      <Flex justify="space-between" align="center" style={{ marginBottom: 24 }}>
        <div>
          <Title level={2} style={{ margin: 0 }}>{t('schedule.title', 'Manage Schedule')}</Title>
          <Text type="secondary">{t('schedule.subtitle', 'Set your recurring weekly availability.')}</Text>
        </div>
        <Button
          type="primary"
          icon={<IconPlus size={16} />}
          onClick={() => { reset(INITIAL_FORM_VALUES); setIsModalOpen(true) }}
        >
          {t('schedule.add_availability', 'Add Availability')}
        </Button>
      </Flex>

      <Row gutter={[24, 24]}>
        {/* Left Column: Weekly Hours */}
        <Col xs={24} lg={16}>
          <Card
            title={t('schedule.weekly_hours', 'Weekly Hours')}
            bordered={false}
            style={{ boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.03), 0 1px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px 0 rgba(0, 0, 0, 0.02)' }}
          >
            <div style={{ marginBottom: 16 }}>
              <Space wrap>
                {daysOptions.map(day => (
                  <Button
                    key={day.value}
                    type={parseInt(activeTab) === day.value ? 'primary' : 'default'}
                    onClick={() => setActiveTab(String(day.value))}
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
              locale={{ emptyText: t('schedule.no_slots', 'No availability slots configured for this day.') }}
            />
          </Card>

          {/* Time Off Section */}
          <Card
            title={t('schedule.time_off', 'Time Off & Holidays')}
            style={{ marginTop: 24, boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.03)' }}
            bordered={false}
            extra={
              <Button
                type="dashed"
                icon={<IconPlus size={14} />}
                onClick={() => setIsTimeOffModalOpen(true)}
              >
                {t('common.add', 'Add')}
              </Button>
            }
          >
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {/* DEBUG: Remove after verifying */}
              <div style={{ fontSize: 10, fontFamily: 'monospace', whiteSpace: 'pre-wrap' }}>
                {JSON.stringify(exceptions, null, 2)}
              </div>
              {exceptions.length > 0 ? (
                exceptions.map((ex: ScheduleException) => (
                  <Card key={ex.id} size="small" type="inner" bodyStyle={{ padding: '8px 12px' }}>
                    <Flex justify="space-between" align="center">
                      <Space direction="vertical" size={2}>
                        <Space>
                          <IconCalendarEvent size={14} style={{ color: '#64748b' }} />
                          <Text strong>
                            {dayjs(ex.start_date).isSame(dayjs(ex.end_date), 'day')
                              ? dayjs(ex.start_date).format('MMM D, YYYY')
                              : `${dayjs(ex.start_date).format('MMM D')} - ${dayjs(ex.end_date).format('MMM D, YYYY')}`
                            }
                          </Text>
                        </Space>
                        <Text type="secondary" style={{ fontSize: 12, paddingLeft: 20 }}>
                          {ex.reason || 'Day Off'}
                        </Text>
                      </Space>
                      <Popconfirm
                        title={t('common.are_you_sure')}
                        onConfirm={() => handleDeleteException(ex.id)}
                      >
                        <Button type="text" danger icon={<IconTrash size={14} />} size="small" />
                      </Popconfirm>
                    </Flex>
                  </Card>
                ))
              ) : (
                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={t('schedule.no_time_off', 'No time off scheduled')} />
              )}
            </div>
          </Card>
        </Col>

        {/* --- TIME OFF MODAL --- */}
        <Modal
          title={t('schedule.add_time_off', 'Add Time Off')}
          open={isTimeOffModalOpen}
          onCancel={() => setIsTimeOffModalOpen(false)}
          footer={null}
        >
          <Form
            form={form}
            layout="vertical"
            onFinish={handleCreateException}
            initialValues={{ reason: 'Holiday', type: 'single' }}
          >
            <Form.Item name="type" style={{ marginBottom: 12 }}>
              <Radio.Group
                optionType="button"
                buttonStyle="solid"
              >
                <Radio.Button value="single">{t('common.single_day', 'Single Day')}</Radio.Button>
                <Radio.Button value="range">{t('common.date_range', 'Date Range')}</Radio.Button>
              </Radio.Group>
            </Form.Item>

            {isRange ? (
              <Form.Item
                label={t('common.date_range', 'Date Range')}
                name="range"
                rules={[{ required: true, message: 'Please select dates' }]}
              >
                <DatePicker.RangePicker style={{ width: '100%' }} format="MMM D, YYYY" />
              </Form.Item>
            ) : (
              <Form.Item
                label={t('common.date', 'Date')}
                name="date"
                rules={[{ required: true, message: 'Please select date' }]}
              >
                <DatePicker style={{ width: '100%' }} format="MMM D, YYYY" />
              </Form.Item>
            )}

            <Form.Item label={t('common.reason', 'Reason')} name="reason">
              <Select>
                <Option value="Holiday">Holiday</Option>
                <Option value="Vacation">Vacation</Option>
                <Option value="Personal">Personal</Option>
                <Option value="Conference">Conference</Option>
                <Option value="Other">Other</Option>
              </Select>
              {/* Fallback to simple input via free text if Select is clearable/editable, but standard Select is fine for MVP */}
            </Form.Item>

            <Flex justify="end" gap="small" style={{ marginTop: 24 }}>
              <Button onClick={() => setIsTimeOffModalOpen(false)}>
                {t('common.cancel', 'Cancel')}
              </Button>
              <Button type="primary" htmlType="submit">
                {t('common.save', 'Save')}
              </Button>
            </Flex>
          </Form>
        </Modal>

        {/* Right Column: Upcoming */}
        <Col xs={24} lg={8}>
          <Card title={t('schedule.upcoming', 'Upcoming Appointments')} bordered={false} style={{ boxShadow: '0 1px 2px 0 rgba(0,0,0,0.03)' }}>
            {upcomingAppointments.length > 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                {upcomingAppointments.map((appt: Appointment) => (
                  <Card key={appt.id} size="small" type="inner">
                    <Flex justify="space-between" align="start">
                      <Space>
                        <div style={{ width: 32, height: 32, borderRadius: '50%', backgroundColor: '#f1f5f9', overflow: 'hidden' }}>
                          <img src={appt.patient.avatar_url || `https://ui-avatars.com/api/?name=${appt.patient.first_name}+${appt.patient.last_name}`} alt="Pt" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        </div>
                        <div>
                          <Text strong>{appt.patient.first_name} {appt.patient.last_name}</Text>
                          <div style={{ fontSize: 12, color: '#64748b' }}>
                            {dayjs(appt.starts_at).format('MMM D, h:mm A')}
                          </div>
                        </div>
                      </Space>
                      <Tag color={appt.type === 'video' ? 'blue' : 'green'}>
                        {appt.type === 'video' ? <IconVideo size={12} /> : <IconUser size={12} />}
                      </Tag>
                    </Flex>
                  </Card>
                ))}
              </div>
            ) : (
              <Empty description={t('schedule.no_upcoming', 'No upcoming appointments')} image={Empty.PRESENTED_IMAGE_SIMPLE} />
            )}
          </Card>
        </Col>
      </Row>

      {/* --- ADD SLOT MODAL --- */}
      <Modal
        title={t('schedule.setup_availability', 'Setup Availability')}
        open={isModalOpen}
        onCancel={() => setIsModalOpen(false)}
        footer={[
          <Button key="preview" onClick={handlePreview} loading={previewMutation.isPending}>
            {t('common.preview', 'Preview Slots')}
          </Button>,
          <Button key="cancel" onClick={() => setIsModalOpen(false)}>
            {t('common.cancel', 'Cancel')}
          </Button>,
          <Button key="submit" type="primary" onClick={handleSubmit(onSubmit)} loading={saveMutation.isPending}>
            {t('common.save', 'Save availability')}
          </Button>
        ]}
        width={800}
      >
        <Form layout="vertical" style={{ marginTop: 24 }}>

          {/* Scope Selection */}
          <Card size="small" style={{ backgroundColor: '#f8fafc', marginBottom: 24 }}>
            <Row gutter={16}>
              <Col span={12}>
                <Form.Item label={t('schedule.consultation_mode', 'Consultation Mode')}>
                  <Controller
                    name="scope.consultationMode"
                    control={control}
                    render={({ field }) => (
                      <Select {...field} style={{ width: '100%' }}>
                        <Option value="in_person"><IconUser size={14} /> In-Person</Option>
                        <Option value="video"><IconVideo size={14} /> Video Call</Option>
                        <Option value="phone"><IconPhone size={14} /> Phone Call</Option>
                      </Select>
                    )}
                  />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item label={t('schedule.timezone', 'Timezone')}>
                  <Controller
                    name="scope.timezone"
                    control={control}
                    render={({ field }) => (
                      <Select {...field} disabled style={{ width: '100%' }}>
                        <Option value={DEFAULT_TIMEZONE}>{DEFAULT_TIMEZONE}</Option>
                      </Select>
                    )}
                  />
                </Form.Item>
              </Col>
            </Row>
          </Card>

          <Divider orientation="left">Weekly Schedule</Divider>

          {/* Days Configuration */}
          <div style={{ maxHeight: 400, overflowY: 'auto' }}>
            {dayFields.map((field, index) => {
              // We only iterate configured days (Mon-Fri by default)
              const currentDay = watch(`days.${index}`)
              return (
                <Card key={field.id} size="small" style={{ marginBottom: 12, borderColor: currentDay.enabled ? '#d9d9d9' : '#f0f0f0' }}>
                  <Flex align="start" gap="middle">
                    <div style={{ minWidth: 60, paddingTop: 6 }}>
                      <Controller
                        name={`days.${index}.enabled`}
                        control={control}
                        render={({ field: f }) => (
                          <Switch
                            checked={f.value}
                            onChange={f.onChange}
                            size="small"
                          />
                        )}
                      />
                      <div style={{ marginTop: 8, fontWeight: 600 }}>
                        {daysOptions.find(d => d.value === field.dayOfWeek)?.label}
                      </div>
                    </div>

                    {currentDay.enabled && (
                      <div style={{ flex: 1 }}>
                        {/* Windows logic simplified: assume 1 window per day for MVP UIs, or map windows */}
                        {/* Accessing existing window 0 */}
                        <Row gutter={16} align="middle">
                          <Col span={8}>
                            <Form.Item label="Hours" style={{ marginBottom: 0 }}>
                              <Space.Compact>
                                <Controller
                                  name={`days.${index}.windows.0.workStartLocal`}
                                  control={control}
                                  render={({ field: f }) => (
                                    <TimePicker
                                      format="HH:mm"
                                      value={f.value ? dayjs(f.value, 'HH:mm') : null}
                                      onChange={(t) => f.onChange(t ? t.format('HH:mm') : null)}
                                      placeholder="Start"
                                      style={{ width: 90 }}
                                    />
                                  )}
                                />
                                <Controller
                                  name={`days.${index}.windows.0.workEndLocal`}
                                  control={control}
                                  render={({ field: f }) => (
                                    <TimePicker
                                      format="HH:mm"
                                      value={f.value ? dayjs(f.value, 'HH:mm') : null}
                                      onChange={(t) => f.onChange(t ? t.format('HH:mm') : null)}
                                      placeholder="End"
                                      style={{ width: 90 }}
                                    />
                                  )}
                                />
                              </Space.Compact>
                            </Form.Item>
                          </Col>
                          <Col span={6}>
                            <Form.Item label="Interval" style={{ marginBottom: 0 }}>
                              <Controller
                                name={`days.${index}.windows.0.slotIntervalMinutes`}
                                control={control}
                                render={({ field: f }) => (
                                  <Select {...field} style={{ width: '100%' }}>
                                    <Option value={15}>15 m</Option>
                                    <Option value={20}>20 m</Option>
                                    <Option value={30}>30 m</Option>
                                    <Option value={45}>45 m</Option>
                                    <Option value={60}>1 h</Option>
                                  </Select>
                                )}
                              />
                            </Form.Item>
                          </Col>
                          {/* Breaks can be added here in future v2 */}
                        </Row>
                      </div>
                    )}

                    {!currentDay.enabled && (
                      <Text type="secondary" style={{ paddingTop: 6 }}>Not Available</Text>
                    )}
                  </Flex>
                </Card>
              )
            })}
          </div>

          {previewData && (
            <div style={{ marginTop: 24, padding: 16, backgroundColor: '#f6ffed', borderRadius: 8, border: '1px solid #b7eb8f' }}>
              <Text strong style={{ color: '#389e0d' }}>
                Preview: {previewData.summary.totalSlots} slots will be created across {previewData.summary.daysEnabled} days next week.
              </Text>
            </div>
          )}

        </Form>
      </Modal>
    </div>
  )
}

export default DoctorSchedule
