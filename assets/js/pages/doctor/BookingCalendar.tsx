import { useState } from 'react'
import { Calendar, Badge, Modal, Button, Card, Typography, message, Flex } from 'antd'
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'
import axios from 'axios'
import { useTranslation } from 'react-i18next'
import { IconCalendar, IconPlus } from '@tabler/icons-react'
import { useIsMobile } from '@/lib/device'

import type { AppPageProps } from '@/types/app'
import DaySlotsView from '../../components/calendar/DaySlotsView'
import BookingForm from '../../components/calendar/BookingForm'

const { Title, Text } = Typography

type Props = AppPageProps<{
    doctor: {
        id: string
        firstName: string
        lastName: string
    }
    today: string
    monthCounts: Record<string, number>
}>

type Slot = {
    starts_at: string
    ends_at: string
    status: 'free' | 'booked'
}

const BookingCalendarPage = ({ doctor, today, monthCounts }: Props) => {
    const { t } = useTranslation('default')
    const isMobile = useIsMobile()

    const [counts, setCounts] = useState<Record<string, number>>(monthCounts || {})
    const [selectedDate, setSelectedDate] = useState<Dayjs | null>(null)
    const [slots, setSlots] = useState<Slot[]>([])
    const [showDayView, setShowDayView] = useState(false)
    const [showBookingForm, setShowBookingForm] = useState(false)
    const [selectedSlot, setSelectedSlot] = useState<Slot | null>(null)

    const onPanelChange = async (date: Dayjs) => {
        const year = date.year()
        const month = date.month() + 1 // dayjs months are 0-indexed

        try {
            const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content')
            const response = await axios.post('/dashboard/doctor/calendar/month-data', {
                year,
                month
            }, {
                headers: {
                    'x-csrf-token': csrfToken
                }
            })

            setCounts(response.data.counts)
        } catch (error) {
            console.error('Failed to fetch month data:', error)
            message.error(t('Failed to load calendar data'))
        }
    }

    const onSelectDate = async (date: Dayjs) => {
        setSelectedDate(date)

        try {
            const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content')
            const response = await axios.post('/dashboard/doctor/calendar/day-slots', {
                date: date.format('YYYY-MM-DD')
            }, {
                headers: {
                    'x-csrf-token': csrfToken
                }
            })

            setSlots(response.data.slots)
            setShowDayView(true)
        } catch (error) {
            console.error('Failed to fetch day slots:', error)
            message.error(t('Failed to load day schedule'))
        }
    }

    const dateCellRender = (date: Dayjs) => {
        if (!counts) return null;
        const dateStr = date.format('YYYY-MM-DD')
        const count = counts[dateStr] || 0

        if (count === 0) return null

        return (
            <div style={{ textAlign: 'center' }}>
                <Badge count={count} style={{ backgroundColor: '#0d9488' }} />
            </div>
        )
    }

    const handleSlotClick = (slot: Slot) => {
        if (slot.status === 'free') {
            setSelectedSlot(slot)
            setShowDayView(false)
            setShowBookingForm(true)
        }
    }

    const handleBookingCreated = () => {
        setShowBookingForm(false)
        setSelectedSlot(null)

        // Refresh the day view
        if (selectedDate) {
            onSelectDate(selectedDate)
        }

        message.success(t('Appointment created successfully!'))
    }

    const handleCloseDayView = () => {
        setShowDayView(false)
        setSelectedDate(null)
        setSlots([])
    }

    const handleCloseBookingForm = () => {
        setShowBookingForm(false)
        setSelectedSlot(null)
        setShowDayView(true)
    }

    return (
        <div style={{ padding: isMobile ? 16 : 24, maxWidth: 1200, margin: '0 auto' }}>
            <Flex justify="space-between" align="center" wrap="wrap" gap={12} style={{ marginBottom: 24 }}>
                <div>
                    <Text type="secondary" style={{ textTransform: 'uppercase', letterSpacing: 0.8, fontWeight: 600 }}>
                        {t('Practice')}
                    </Text>
                    <Title level={2} style={{ margin: 0 }}>
                        {t('Booking Calendar')}
                    </Title>
                    <Text type="secondary">{t('View your schedule and create bookings')}</Text>
                </div>
            </Flex>

            <Card
                bordered={false}
                style={{ borderRadius: 16, boxShadow: '0 1px 8px rgba(0,0,0,0.05)' }}
            >
                <Calendar
                    dateCellRender={dateCellRender}
                    onPanelChange={onPanelChange}
                    onSelect={onSelectDate}
                />
            </Card>

            {/* Day View Modal */}
            <Modal
                open={showDayView}
                onCancel={handleCloseDayView}
                footer={null}
                width={isMobile ? '100%' : 600}
                title={
                    <Flex align="center" gap={8}>
                        <IconCalendar size={20} />
                        <span>
                            {selectedDate ? selectedDate.format('dddd, MMMM D, YYYY') : ''}
                        </span>
                    </Flex>
                }
            >
                {selectedDate && (
                    <DaySlotsView
                        date={selectedDate}
                        slots={slots}
                        onSlotClick={handleSlotClick}
                    />
                )}
            </Modal>

            {/* Booking Form Modal */}
            <Modal
                open={showBookingForm}
                onCancel={handleCloseBookingForm}
                footer={null}
                width={isMobile ? '100%' : 700}
                title={
                    <Flex align="center" gap={8}>
                        <IconPlus size={20} />
                        <span>{t('Create Booking')}</span>
                    </Flex>
                }
            >
                {selectedSlot && selectedDate && (
                    <BookingForm
                        slot={selectedSlot}
                        date={selectedDate}
                        doctorId={doctor.id}
                        onSuccess={handleBookingCreated}
                        onCancel={handleCloseBookingForm}
                    />
                )}
            </Modal>
        </div>
    )
}

export default BookingCalendarPage
