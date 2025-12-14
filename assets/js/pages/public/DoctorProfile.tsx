import {
  Tag,
  Button,
  Card,
  Divider,
  Row,
  Col,
  Space,
  List,
  Tabs,
  Input,
  Typography,
  Avatar,
  Segmented
} from 'antd'
import { HeartOutlined } from '@ant-design/icons'
import {
  IconCalendar,
  IconClock,
  IconMapPin,
  IconPhoneCall,
  IconShieldCheck,
  IconVideo,
  IconInfoCircle,
  IconStethoscope,
  IconUser,
  IconChevronLeft,
  IconChevronRight
} from '@tabler/icons-react'
import { useState } from 'react'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import { format } from 'date-fns'

const { Title, Text } = Typography
const { TextArea } = Input

export type DoctorProfile = {
  id: string
  fullName: string
  firstName: string
  lastName: string
  title: string | null
  verified: boolean
  profileImageUrl: string | null
  specialty: { name: string; slug: string } | null
  city: string | null
  address: string | null
  hospitalAffiliation: string | null
  yearsOfExperience: number | null
  bio: string | null
  subSpecialties: string[]
  clinicalProcedures: string[]
  conditionsTreated: string[]
  languages: string[]
  awards: string[]
  telemedicineAvailable: boolean
  consultationFee: number | null
  nextAvailableSlot: string | null
}

type AvailabilityDay = {
  date: string
  slots: { startsAt: string; endsAt: string; status: string }[]
}

type PageProps = AppPageProps<{
  doctor: DoctorProfile
  availability: AvailabilityDay[]
  startDate: string
  appreciation: {
    totalDistinctPatients: number
    last30dDistinctPatients: number
    lastAppreciatedAt: string | null
  }
}>

const APP_LOCALE = 'en-US'

export default function DoctorProfilePage({ doctor, app, auth, availability, startDate, appreciation }: PageProps) {
  const { t } = useTranslation('default')
  const [selectedDateIndex, setSelectedDateIndex] = useState(0)
  const [selectedSlot, setSelectedSlot] = useState<{ startsAt: string; endsAt: string } | null>(null)
  const [notes, setNotes] = useState('')
  const [appointmentType, setAppointmentType] = useState<'in_person' | 'telemedicine'>(
    doctor.telemedicineAvailable ? 'telemedicine' : 'in_person'
  )
  const [isBooking, setIsBooking] = useState(false)

  const days = availability || []
  const currentDay = days[selectedDateIndex]

  // Pagination Logic
  const currentStart = startDate ? new Date(startDate) : new Date()

  const handleNextWeek = () => {
    const nextDate = new Date(currentStart)
    nextDate.setDate(nextDate.getDate() + 7)
    router.visit(`/doctors/${doctor.id}?date=${format(nextDate, 'yyyy-MM-dd')}`, {
      preserveScroll: true,
      only: ['availability', 'startDate']
    })
    setSelectedDateIndex(0)
    setSelectedSlot(null)
  }

  const handlePrevWeek = () => {
    const prevDate = new Date(currentStart)
    prevDate.setDate(prevDate.getDate() - 7)
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    if (prevDate < today) prevDate.setTime(today.getTime())

    router.visit(`/doctors/${doctor.id}?date=${format(prevDate, 'yyyy-MM-dd')}`, {
      preserveScroll: true,
      only: ['availability', 'startDate']
    })
    setSelectedDateIndex(0)
    setSelectedSlot(null)
  }

  const canGoBack = currentStart > new Date(new Date().setHours(0, 0, 0, 0))


  const handleBook = () => {
    if (!selectedSlot || isBooking) return
    if (!auth.authenticated) {
      router.visit('/login')
      return
    }

    router.post(`/doctors/${doctor.id}/book`, {
      booking: {
        starts_at: selectedSlot.startsAt,
        ends_at: selectedSlot.endsAt,
        appointment_type: appointmentType,
        notes
      }
    }, {
      onStart: () => setIsBooking(true),
      onFinish: () => setIsBooking(false)
    })
  }

  const tabItems = [
    {
      key: 'about',
      label: <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}><IconUser size={16} /> About & Expertise</span>,
      children: (
        <Row gutter={40}>
          <Col xs={24} md={16}>
            <div style={{ marginBottom: 40 }}>
              <Title level={4} style={{ marginBottom: 16 }}>Biography</Title>
              <Text style={{ lineHeight: 1.7, color: 'rgba(0,0,0,0.65)' }}>{doctor.bio || "No biography available."}</Text>
            </div>

            {(doctor.clinicalProcedures.length > 0 || doctor.conditionsTreated.length > 0) && (
              <div>
                <Title level={4} style={{ marginBottom: 16 }}>Medical Expertise</Title>
                <Row gutter={24}>
                  <Col span={12}>
                    <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13, color: 'rgba(0,0,0,0.45)', textTransform: 'uppercase' }}>Procedures</Text>
                    <List<string>
                      size="small"
                      dataSource={doctor.clinicalProcedures.slice(0, 5)}
                      renderItem={(item) => (
                        <List.Item style={{ padding: '8px 0', border: 'none' }}>
                          <Space>
                            <IconStethoscope size={16} color="#0d9488" />
                            <Text>{item}</Text>
                          </Space>
                        </List.Item>
                      )}
                      split={false}
                    />
                  </Col>
                  <Col span={12}>
                    <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13, color: 'rgba(0,0,0,0.45)', textTransform: 'uppercase' }}>Conditions Treated</Text>
                    <List<string>
                      size="small"
                      dataSource={doctor.conditionsTreated.slice(0, 5)}
                      renderItem={(item) => (
                        <List.Item style={{ padding: '8px 0', border: 'none' }}>
                          <Space>
                            <IconStethoscope size={16} color="#0d9488" />
                            <Text>{item}</Text>
                          </Space>
                        </List.Item>
                      )}
                      split={false}
                    />
                  </Col>
                </Row>
              </div>
            )}
          </Col>
          {/* Side Info in About Tab */}
          <Col xs={24} md={8}>
            {doctor.subSpecialties.length > 0 && (
              <Card bordered style={{ borderRadius: 8 }}>
                <Text strong style={{ display: 'block', marginBottom: 16 }}>Special Interests</Text>
                <Space size={[0, 8]} wrap>
                  {doctor.subSpecialties.map((s: string) => <Tag key={s} style={{ margin: 0, marginRight: 8 }}>{s}</Tag>)}
                </Space>
              </Card>
            )}
          </Col>
        </Row>
      )
    },
    {
      key: 'location',
      label: <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}><IconMapPin size={16} /> Location</span>,
      children: (
        <Row gutter={40}>
          <Col xs={24} md={8}>
            <div style={{ marginBottom: 20 }}>
              <Title level={4} style={{ marginBottom: 8 }}>Practice Address</Title>
              <Text style={{ fontSize: 18, fontWeight: 500, display: 'block' }}>{doctor.address}</Text>
              <Text type="secondary">{doctor.city}</Text>
            </div>

            {doctor.hospitalAffiliation && (
              <div>
                <Text strong style={{ fontSize: 13, color: 'rgba(0,0,0,0.45)', textTransform: 'uppercase', display: 'block' }}>Affiliation</Text>
                <Text>{doctor.hospitalAffiliation}</Text>
              </div>
            )}
          </Col>
          <Col xs={24} md={16}>
            <div style={{ height: 400, backgroundColor: '#f5f5f5', borderRadius: 8, overflow: 'hidden', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'rgba(0,0,0,0.45)' }}>
              <IconMapPin size={32} style={{ marginBottom: 4 }} />
              <Text>Interactive Map</Text>
              <Button type="link" size="small">Get Directions</Button>
            </div>
          </Col>
        </Row>
      )
    }
  ]

  return (
    <div style={{ padding: '40px 24px', maxWidth: 1200, margin: '0 auto' }}>
      {/* Profile Header */}
      <Card bordered style={{ borderRadius: 12, marginBottom: 40 }} bodyStyle={{ padding: 30 }}>
        <div style={{ display: 'flex', gap: 32, alignItems: 'flex-start' }}>
          <Avatar
            src={doctor.profileImageUrl}
            size={140}
            style={{ borderRadius: 12, backgroundColor: '#0d9488', fontSize: 56, flexShrink: 0 }}
          >
            {doctor.firstName?.[0]}
          </Avatar>

          <div style={{ flex: 1 }}>
            <Space direction="vertical" size={8} style={{ width: '100%' }}>
              <div>
                <Title level={2} style={{ margin: 0, marginBottom: 4 }}>
                  {doctor.title || 'Dr.'} {doctor.fullName}
                </Title>
                <Text type="secondary" style={{ fontSize: 18, fontWeight: 500 }}>
                  {doctor.specialty?.name || 'Medical Specialist'}
                </Text>
              </div>

              <Space wrap size={[8, 8]} style={{ marginTop: 4 }}>
                {doctor.verified && (
                  <Tag icon={<IconShieldCheck size={14} />} color="success" style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    Verified
                  </Tag>
                )}
                <Tag color="magenta" icon={<HeartOutlined />} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                  Appreciated by {appreciation.totalDistinctPatients} patients
                </Tag>
                {appreciation.last30dDistinctPatients > 0 && (
                  <Tag color="cyan">+{appreciation.last30dDistinctPatients} in last 30 days</Tag>
                )}
              </Space>

              <Space size="large" style={{ marginTop: 16, color: 'rgba(0,0,0,0.65)' }}>
                <Space size={6}>
                  <IconMapPin size={18} style={{ opacity: 0.6 }} />
                  <Text>{doctor.city}</Text>
                </Space>
                {doctor.yearsOfExperience && (
                  <Space size={6}>
                    <IconStethoscope size={18} style={{ opacity: 0.6 }} />
                    <Text>{doctor.yearsOfExperience}+ Years Exp.</Text>
                  </Space>
                )}
              </Space>
            </Space>
          </div>

          <div style={{ textAlign: 'right', minWidth: 120 }}>
            <Text type="secondary" style={{ fontSize: 12, textTransform: 'uppercase', fontWeight: 700, display: 'block', marginBottom: 4 }}>
              Consultation
            </Text>
            <Text strong style={{ fontSize: 28, color: '#0d9488' }}>
              {doctor.consultationFee ? `€${doctor.consultationFee}` : 'Ask'}
            </Text>
          </div>
        </div>
      </Card>

      <Row gutter={40}>
        <Col span={24}>

          {/* Centralized Booking Section */}
          <Card bordered style={{ borderRadius: 12, marginBottom: 50 }} id="book-appointment" bodyStyle={{ padding: 32 }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Title level={3} style={{ margin: 0 }}>Book Appointment</Title>
                {doctor.telemedicineAvailable && (
                  <Segmented
                    value={appointmentType}
                    onChange={(val: any) => setAppointmentType(val)}
                    options={[
                      { label: 'Clinic Visit', value: 'in_person', icon: <IconMapPin size={14} /> },
                      { label: 'Video Call', value: 'telemedicine', icon: <IconVideo size={14} /> }
                    ]}
                  />
                )}
              </div>

              <Divider style={{ margin: 0 }} />

              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                  <Text strong>Select Date</Text>
                  <Space>
                    <Button icon={<IconChevronLeft size={16} />} disabled={!canGoBack} onClick={handlePrevWeek} />
                    <Text strong>{format(currentStart, 'MMMM yyyy')}</Text>
                    <Button icon={<IconChevronRight size={16} />} onClick={handleNextWeek} />
                  </Space>
                </div>

                <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }}>
                  {days.map((day: AvailabilityDay, index: number) => {
                    const isSelected = selectedDateIndex === index
                    const d = new Date(day.date)
                    return (
                      <Card
                        key={day.date}
                        hoverable
                        bordered={!isSelected}
                        style={{
                          minWidth: 80,
                          borderColor: isSelected ? '#13c2c2' : undefined,
                          backgroundColor: isSelected ? '#e6fffa' : 'white',
                          cursor: 'pointer',
                          borderRadius: 8
                        }}
                        bodyStyle={{ padding: 8, textAlign: 'center' }}
                        onClick={() => { setSelectedDateIndex(index); setSelectedSlot(null); }}
                      >
                        <Text style={{ fontSize: 12, color: isSelected ? '#0d9488' : 'rgba(0,0,0,0.45)', textTransform: 'uppercase', fontWeight: 700, display: 'block' }}>
                          {d.toLocaleDateString(APP_LOCALE, { weekday: 'short' })}
                        </Text>
                        <Text strong style={{ fontSize: 18, color: isSelected ? '#0d9488' : undefined }}>{d.getDate()}</Text>
                      </Card>
                    )
                  })}
                </div>
              </div>

              <div>
                <Text strong style={{ display: 'block', marginBottom: 12 }}>Available Slots</Text>
                {currentDay?.slots?.filter((s: any) => s.status === 'free').length > 0 ? (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(100px, 1fr))', gap: 12 }}>
                    {currentDay.slots
                      .filter((slot: any) => slot.status === 'free')
                      .map((slot: any) => {
                        const slotDate = new Date(slot.startsAt)
                        const isPast = slotDate < new Date()
                        const isSelected = selectedSlot?.startsAt === slot.startsAt
                        return (
                          <Button
                            key={slot.startsAt}
                            type={isSelected ? 'primary' : 'default'}
                            onClick={() => !isPast && setSelectedSlot(slot)}
                            disabled={isPast}
                            style={isPast ? { textDecoration: 'line-through' } : {}}
                            block
                          >
                            {slotDate.toLocaleTimeString(APP_LOCALE, { hour: '2-digit', minute: '2-digit' })}
                          </Button>
                        )
                      })
                    }
                  </div>
                ) : (
                  <div style={{ display: 'flex', justifyContent: 'center', padding: 20, backgroundColor: '#f5f5f5', borderRadius: 8 }}>
                    <Text type="secondary">No available slots for this date.</Text>
                  </div>
                )}
              </div>

              {selectedSlot && (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                  <TextArea
                    placeholder="Reason for visit (optional)..."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    rows={3}
                    disabled={isBooking}
                  />

                  <Button
                    type="primary"
                    size="large"
                    block
                    onClick={handleBook}
                    loading={isBooking}
                    disabled={!selectedSlot || isBooking}
                  >
                    Confirm Booking
                  </Button>
                  <Text type="secondary" style={{ fontSize: 12, textAlign: 'center', display: 'block' }}>No payment required to book.</Text>
                </div>
              )}
            </div>
          </Card>

          {/* Details Tabs */}
          <Tabs defaultActiveKey="about" items={tabItems} size="large" />

        </Col>
      </Row>
    </div>
  )
}
