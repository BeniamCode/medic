import { Card, Empty, Timeline, Tag, Typography } from 'antd'
import type { Dayjs } from 'dayjs'
import dayjs from 'dayjs'
import { useTranslation } from 'react-i18next'
import { IconCheck, IconX, IconClock } from '@tabler/icons-react'

const { Text } = Typography

type Slot = {
    starts_at: string
    ends_at: string
    status: 'free' | 'booked'
}

type Props = {
    date: Dayjs
    slots: Slot[]
    onSlotClick: (slot: Slot) => void
}

const DaySlotsView = ({ date, slots, onSlotClick }: Props) => {
    const { t } = useTranslation('default')

    if (slots.length === 0) {
        return (
            <Empty
                description={t('No availability set for this day')}
                style={{ padding: '40px 0' }}
            />
        )
    }

    const freeSlots = slots.filter(s => s.status === 'free')
    const bookedSlots = slots.filter(s => s.status === 'booked')

    return (
        <div>
            <div style={{ marginBottom: 24 }}>
                <Text type="secondary">
                    {t('{{free}} available, {{booked}} booked', {
                        free: freeSlots.length,
                        booked: bookedSlots.length
                    })}
                </Text>
            </div>

            <div style={{ maxHeight: 500, overflowY: 'auto' }}>
                <Timeline>
                    {slots.map((slot, index) => {
                        const startTime = dayjs(slot.starts_at).format('HH:mm')
                        const endTime = dayjs(slot.ends_at).format('HH:mm')
                        const isFree = slot.status === 'free'

                        return (
                            <Timeline.Item
                                key={index}
                                dot={
                                    isFree ? (
                                        <IconCheck size={16} style={{ color: '#10b981' }} />
                                    ) : (
                                        <IconX size={16} style={{ color: '#ef4444' }} />
                                    )
                                }
                            >
                                <Card
                                    size="small"
                                    hoverable={isFree}
                                    onClick={() => isFree && onSlotClick(slot)}
                                    style={{
                                        cursor: isFree ? 'pointer' : 'default',
                                        backgroundColor: isFree ? '#f0fdf4' : '#fef2f2',
                                        borderColor: isFree ? '#10b981' : '#ef4444',
                                        marginBottom: 8
                                    }}
                                >
                                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                                            <IconClock size={16} />
                                            <Text strong>{startTime} - {endTime}</Text>
                                        </div>
                                        <Tag color={isFree ? 'success' : 'error'}>
                                            {isFree ? t('Available') : t('Booked')}
                                        </Tag>
                                    </div>
                                </Card>
                            </Timeline.Item>
                        )
                    })}
                </Timeline>
            </div>
        </div>
    )
}

export default DaySlotsView
