import { useState, useEffect } from 'react'
import { Form, Input, Button, Select, Alert, Spin, Typography, Space, Card, Flex, Tag } from 'antd'
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'
import axios from 'axios'
import { useTranslation } from 'react-i18next'
import { IconUser, IconMail, IconPhone, IconNotes } from '@tabler/icons-react'

const { Text } = Typography
const { TextArea } = Input

type Slot = {
    starts_at: string
    ends_at: string
    status: 'free' | 'booked'
}

type Patient = {
    id: string
    first_name: string
    last_name: string
    email?: string
    phone?: string
    doctor_initiated: boolean
}

type Props = {
    slot: Slot
    date: Dayjs
    doctorId: string
    onSuccess: () => void
    onCancel: () => void
}

const BookingForm = ({ slot, date, doctorId, onSuccess, onCancel }: Props) => {
    const { t } = useTranslation('default')
    const [form] = Form.useForm()

    const [searchingPatient, setSearchingPatient] = useState(false)
    const [foundPatients, setFoundPatients] = useState<Patient[]>([])
    const [selectedPatientId, setSelectedPatientId] = useState<string | null>(null)
    const [submitting, setSubmitting] = useState(false)
    const [searchDebounce, setSearchDebounce] = useState<NodeJS.Timeout | null>(null)

    const startTime = dayjs(slot.starts_at).format('HH:mm')
    const endTime = dayjs(slot.ends_at).format('HH:mm')

    const searchPatient = async (email: string, phone: string) => {
        if (!email && !phone) {
            setFoundPatients([])
            return
        }

        setSearchingPatient(true)

        try {
            const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content')
            const response = await axios.post('/dashboard/doctor/calendar/search-patient', {
                email: email || '',
                phone: phone || ''
            }, {
                headers: {
                    'x-csrf-token': csrfToken
                }
            })

            setFoundPatients(response.data.patients || [])
        } catch (error) {
            console.error('Failed to search patient:', error)
            setFoundPatients([])
        } finally {
            setSearchingPatient(false)
        }
    }

    const handleFieldChange = () => {
        if (searchDebounce) {
            clearTimeout(searchDebounce)
        }

        const timeout = setTimeout(() => {
            const email = form.getFieldValue('email')
            const phone = form.getFieldValue('phone')
            searchPatient(email, phone)
        }, 500)

        setSearchDebounce(timeout)
    }

    const handleSubmit = async (values: any) => {
        setSubmitting(true)

        try {
            const bookingData = {
                starts_at: slot.starts_at,
                ends_at: slot.ends_at,
                duration_minutes: dayjs(slot.ends_at).diff(dayjs(slot.starts_at), 'minute'),
                consultation_mode: values.consultation_mode || 'in_person',
                status: 'confirmed',
                notes: values.notes,
                patient: {
                    id: selectedPatientId,
                    first_name: values.first_name,
                    last_name: values.last_name,
                    email: values.email,
                    phone: values.phone
                }
            }

            const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content')
            await axios.post('/dashboard/doctor/calendar/create-booking', bookingData, {
                headers: {
                    'x-csrf-token': csrfToken
                }
            })

            onSuccess()
        } catch (error: any) {
            console.error('Failed to create booking:', error)

            const errorMsg = error.response?.data?.error || t('Failed to create booking')
            form.setFields([
                {
                    name: 'form_error',
                    errors: [errorMsg]
                }
            ])
        } finally {
            setSubmitting(false)
        }
    }

    useEffect(() => {
        if (foundPatients.length === 1) {
            const patient = foundPatients[0]
            setSelectedPatientId(patient.id)
            form.setFieldsValue({
                first_name: patient.first_name,
                last_name: patient.last_name,
                email: patient.email || '',
                phone: patient.phone || ''
            })
        } else {
            setSelectedPatientId(null)
        }
    }, [foundPatients, form])

    return (
        <div>
            <Alert
                message={t('Booking time slot')}
                description={`${date.format('dddd, MMMM D, YYYY')} • ${startTime} - ${endTime}`}
                type="info"
                showIcon
                style={{ marginBottom: 24 }}
            />

            {foundPatients.length > 0 && (
                <Alert
                    message={t('Patient found!')}
                    description={
                        <Space direction="vertical" style={{ width: '100%' }}>
                            {foundPatients.map(patient => (
                                <Card
                                    key={patient.id}
                                    size="small"
                                    hoverable
                                    onClick={() => {
                                        setSelectedPatientId(patient.id)
                                        form.setFieldsValue({
                                            first_name: patient.first_name,
                                            last_name: patient.last_name,
                                            email: patient.email || '',
                                            phone: patient.phone || ''
                                        })
                                    }}
                                    style={{
                                        backgroundColor: selectedPatientId === patient.id ? '#e0f2fe' : '#fff',
                                        borderColor: selectedPatientId === patient.id ? '#0ea5e9' : '#d9d9d9'
                                    }}
                                >
                                    <Text strong>{patient.first_name} {patient.last_name}</Text>
                                    <br />
                                    <Text type="secondary" style={{ fontSize: 12 }}>
                                        {patient.email} • {patient.phone}
                                    </Text>
                                    {patient.doctor_initiated && (
                                        <Tag color="orange" style={{ marginLeft: 8, fontSize: 11 }}>
                                            {t('Unclaimed')}
                                        </Tag>
                                    )}
                                </Card>
                            ))}
                        </Space>
                    }
                    type="success"
                    showIcon
                    style={{ marginBottom: 24 }}
                />
            )}

            <Form
                form={form}
                layout="vertical"
                onFinish={handleSubmit}
                initialValues={{
                    consultation_mode: 'in_person'
                }}
            >
                <Form.Item name="form_error" style={{ marginBottom: 0 }}>
                    <Input type="hidden" />
                </Form.Item>

                <Form.Item
                    label={t('Email')}
                    name="email"
                    rules={[
                        { required: true, message: t('Please enter email or phone') }
                    ]}
                >
                    <Input
                        prefix={<IconMail size={16} />}
                        placeholder={t('patient@example.com')}
                        onChange={handleFieldChange}
                        suffix={searchingPatient && <Spin size="small" />}
                    />
                </Form.Item>

                <Form.Item
                    label={t('Phone')}
                    name="phone"
                >
                    <Input
                        prefix={<IconPhone size={16} />}
                        placeholder={t('+30 123 456 7890')}
                        onChange={handleFieldChange}
                    />
                </Form.Item>

                <Form.Item
                    label={t('First Name')}
                    name="first_name"
                    rules={[{ required: true, message: t('Please enter first name') }]}
                >
                    <Input
                        prefix={<IconUser size={16} />}
                        placeholder={t('First name')}
                    />
                </Form.Item>

                <Form.Item
                    label={t('Last Name')}
                    name="last_name"
                    rules={[{ required: true, message: t('Please enter last name') }]}
                >
                    <Input
                        prefix={<IconUser size={16} />}
                        placeholder={t('Last name')}
                    />
                </Form.Item>

                <Form.Item
                    label={t('Consultation Mode')}
                    name="consultation_mode"
                >
                    <Select>
                        <Select.Option value="in_person">{t('In-person')}</Select.Option>
                        <Select.Option value="telemedicine">{t('Telemedicine')}</Select.Option>
                    </Select>
                </Form.Item>

                <Form.Item
                    label={t('Notes')}
                    name="notes"
                >
                    <TextArea
                        rows={3}
                        placeholder={t('Additional notes (optional)')}
                    />
                </Form.Item>

                <Flex gap={12} justify="flex-end">
                    <Button onClick={onCancel}>
                        {t('Cancel')}
                    </Button>
                    <Button type="primary" htmlType="submit" loading={submitting}>
                        {t('Create Booking')}
                    </Button>
                </Flex>
            </Form>
        </div>
    )
}

export default BookingForm
