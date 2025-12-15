import {
  Tag,
  Button as DesktopButton,
  Card as DesktopCard,
  Divider,
  Row,
  Col,
  Space,
  List as DesktopList,
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
import { useIsMobile } from '@/lib/device'

// Mobile imports
import {
  Button as MobileButton,
  Card as MobileCard,
  Tag as MobileTag,
  Tabs as MobileTabs,
  TextArea as MobileTextArea,
  Selector,
  Empty
} from 'antd-mobile'
import { LocationOutline, VideoOutline, RightOutline, LeftOutline } from 'antd-mobile-icons'

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

// =============================================================================
// MOBILE DOCTOR PROFILE
// =============================================================================

function MobileDoctorProfile({ doctor, auth, availability, startDate, appreciation }: PageProps) {
  const { t } = useTranslation('default')
  const [selectedDateIndex, setSelectedDateIndex] = useState(0)
  const [selectedSlot, setSelectedSlot] = useState<{ startsAt: string; endsAt: string } | null>(null)
  const [notes, setNotes] = useState('')
  const [appointmentType, setAppointmentType] = useState<'in_person' | 'telemedicine'>(
    doctor.telemedicineAvailable ? 'telemedicine' : 'in_person'
  )
  const [isBooking, setIsBooking] = useState(false)
  const [activeTab, setActiveTab] = useState('book')

  const days = availability || []
  const currentDay = days[selectedDateIndex]
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

  return (
    <div style={{ paddingBottom: 100 }}>
      {/* Profile Header */}
      <div style={{ padding: 16, backgroundColor: '#fff', borderBottom: '1px solid #f0f0f0' }}>
        <div style={{ display: 'flex', gap: 16 }}>
          <Avatar
            src={doctor.profileImageUrl}
            size={80}
            style={{ borderRadius: 12, backgroundColor: '#0d9488', fontSize: 32, flexShrink: 0 }}
          >
            {doctor.firstName?.[0]}
          </Avatar>

          <div style={{ flex: 1 }}>
            <h2 style={{ fontSize: 18, fontWeight: 700, margin: '0 0 4px' }}>
              {doctor.title || 'Dr.'} {doctor.fullName}
            </h2>
            <p style={{ color: '#666', margin: '0 0 8px', fontSize: 14 }}>
              {doctor.specialty?.name || 'Medical Specialist'}
            </p>

            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {doctor.verified && (
                <MobileTag color="success" fill="outline" style={{ fontSize: 11 }}>
                  ✓ Verified
                </MobileTag>
              )}
              <MobileTag color="primary" fill="outline" style={{ fontSize: 11 }}>
                ♥ {appreciation.totalDistinctPatients}
              </MobileTag>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 8, color: '#999', fontSize: 13 }}>
              <LocationOutline fontSize={14} />
              <span>{doctor.city}</span>
              {doctor.yearsOfExperience && (
                <>
                  <span style={{ margin: '0 4px' }}>•</span>
                  <span>{doctor.yearsOfExperience}+ years</span>
                </>
              )}
            </div>
          </div>
        </div>

        <div style={{ marginTop: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <span style={{ fontSize: 12, color: '#999', textTransform: 'uppercase' }}>Consultation</span>
            <div style={{ fontSize: 24, fontWeight: 700, color: '#0d9488' }}>
              {doctor.consultationFee ? `€${doctor.consultationFee}` : 'Ask'}
            </div>
          </div>
          <MobileButton
            color="primary"
            size="large"
            onClick={() => setActiveTab('book')}
            style={{ '--border-radius': '8px' }}
          >
            Book Now
          </MobileButton>
        </div>
      </div>

      {/* Tabs */}
      <MobileTabs activeKey={activeTab} onChange={setActiveTab}>
        <MobileTabs.Tab title="Book" key="book">
          <div style={{ padding: 16 }}>
            {/* Appointment Type */}
            {doctor.telemedicineAvailable && (
              <div style={{ marginBottom: 20 }}>
                <div style={{ fontWeight: 600, marginBottom: 8 }}>Visit Type</div>
                <Selector
                  columns={2}
                  options={[
                    { label: '🏥 Clinic', value: 'in_person' },
                    { label: '📹 Video', value: 'telemedicine' }
                  ]}
                  value={[appointmentType]}
                  onChange={(v) => setAppointmentType((v[0] || 'in_person') as any)}
                />
              </div>
            )}

            {/* Date Selection */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <span style={{ fontWeight: 600 }}>Select Date</span>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <MobileButton
                    size="mini"
                    disabled={!canGoBack}
                    onClick={handlePrevWeek}
                  >
                    <LeftOutline />
                  </MobileButton>
                  <span style={{ fontSize: 13, fontWeight: 500 }}>{format(currentStart, 'MMM yyyy')}</span>
                  <MobileButton size="mini" onClick={handleNextWeek}>
                    <RightOutline />
                  </MobileButton>
                </div>
              </div>

              <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 8 }}>
                {days.map((day, index) => {
                  const isSelected = selectedDateIndex === index
                  const d = new Date(day.date)
                  return (
                    <div
                      key={day.date}
                      onClick={() => { setSelectedDateIndex(index); setSelectedSlot(null) }}
                      style={{
                        minWidth: 56,
                        padding: '8px 12px',
                        textAlign: 'center',
                        borderRadius: 8,
                        border: `1px solid ${isSelected ? '#0d9488' : '#e5e5e5'}`,
                        backgroundColor: isSelected ? '#e6fffa' : '#fff',
                        cursor: 'pointer'
                      }}
                    >
                      <div style={{ fontSize: 11, color: isSelected ? '#0d9488' : '#999', textTransform: 'uppercase', fontWeight: 600 }}>
                        {d.toLocaleDateString(APP_LOCALE, { weekday: 'short' })}
                      </div>
                      <div style={{ fontSize: 18, fontWeight: 600, color: isSelected ? '#0d9488' : '#333' }}>
                        {d.getDate()}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            {/* Time Slots */}
            <div style={{ marginBottom: 20 }}>
              <div style={{ fontWeight: 600, marginBottom: 12 }}>Available Slots</div>
              {currentDay?.slots?.filter((s: any) => s.status === 'free').length > 0 ? (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
                  {currentDay.slots
                    .filter((slot: any) => slot.status === 'free')
                    .map((slot: any) => {
                      const slotDate = new Date(slot.startsAt)
                      const isPast = slotDate < new Date()
                      const isSelected = selectedSlot?.startsAt === slot.startsAt
                      return (
                        <MobileButton
                          key={slot.startsAt}
                          color={isSelected ? 'primary' : 'default'}
                          fill={isSelected ? 'solid' : 'outline'}
                          disabled={isPast}
                          onClick={() => !isPast && setSelectedSlot(slot)}
                          style={{ '--border-radius': '8px' }}
                        >
                          {slotDate.toLocaleTimeString(APP_LOCALE, { hour: '2-digit', minute: '2-digit' })}
                        </MobileButton>
                      )
                    })
                  }
                </div>
              ) : (
                <Empty description="No available slots" />
              )}
            </div>

            {/* Book Button */}
            {selectedSlot && (
              <div>
                <MobileTextArea
                  placeholder="Reason for visit (optional)..."
                  value={notes}
                  onChange={setNotes}
                  rows={2}
                  style={{ marginBottom: 16, '--font-size': '14px' }}
                />
                <MobileButton
                  block
                  color="primary"
                  size="large"
                  loading={isBooking}
                  onClick={handleBook}
                  style={{ '--border-radius': '8px' }}
                >
                  Confirm Booking
                </MobileButton>
                <p style={{ textAlign: 'center', color: '#999', fontSize: 12, marginTop: 8 }}>
                  No payment required to book
                </p>
              </div>
            )}
          </div>
        </MobileTabs.Tab>

        <MobileTabs.Tab title="About" key="about">
          <div style={{ padding: 16 }}>
            <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>Biography</h3>
            <p style={{ color: '#666', lineHeight: 1.6, marginBottom: 24 }}>
              {doctor.bio || "No biography available."}
            </p>

            {doctor.subSpecialties.length > 0 && (
              <div style={{ marginBottom: 24 }}>
                <h4 style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Special Interests</h4>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                  {doctor.subSpecialties.map((s) => (
                    <MobileTag key={s} color="primary" fill="outline">{s}</MobileTag>
                  ))}
                </div>
              </div>
            )}

            {doctor.clinicalProcedures.length > 0 && (
              <div style={{ marginBottom: 24 }}>
                <h4 style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Procedures</h4>
                {doctor.clinicalProcedures.slice(0, 5).map((item) => (
                  <div key={item} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                    <IconStethoscope size={16} color="#0d9488" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </MobileTabs.Tab>

        <MobileTabs.Tab title="Location" key="location">
          <div style={{ padding: 16 }}>
            <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 8 }}>Practice Address</h3>
            <p style={{ fontWeight: 500, marginBottom: 4 }}>{doctor.address}</p>
            <p style={{ color: '#666', marginBottom: 16 }}>{doctor.city}</p>

            {doctor.hospitalAffiliation && (
              <div style={{ marginBottom: 16 }}>
                <span style={{ fontSize: 12, color: '#999', textTransform: 'uppercase' }}>Affiliation</span>
                <p style={{ fontWeight: 500, marginTop: 4 }}>{doctor.hospitalAffiliation}</p>
              </div>
            )}

            <div style={{
              height: 200,
              backgroundColor: '#f5f5f5',
              borderRadius: 12,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#999'
            }}>
              <LocationOutline fontSize={32} />
              <span style={{ marginTop: 8 }}>Map View</span>
            </div>
          </div>
        </MobileTabs.Tab>
      </MobileTabs>
    </div>
  )
}

// =============================================================================
// DESKTOP DOCTOR PROFILE (Original - kept as is)
// =============================================================================

function DesktopDoctorProfile({ doctor, app, auth, availability, startDate, appreciation }: PageProps) {
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
                    <DesktopList<string>
                      size="small"
                      dataSource={doctor.clinicalProcedures.slice(0, 5)}
                      renderItem={(item) => (
                        <DesktopList.Item style={{ padding: '8px 0', border: 'none' }}>
                          <Space>
                            <IconStethoscope size={16} color="#0d9488" />
                            <Text>{item}</Text>
                          </Space>
                        </DesktopList.Item>
                      )}
                      split={false}
                    />
                  </Col>
                  <Col span={12}>
                    <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13, color: 'rgba(0,0,0,0.45)', textTransform: 'uppercase' }}>Conditions Treated</Text>
                    <DesktopList<string>
                      size="small"
                      dataSource={doctor.conditionsTreated.slice(0, 5)}
                      renderItem={(item) => (
                        <DesktopList.Item style={{ padding: '8px 0', border: 'none' }}>
                          <Space>
                            <IconStethoscope size={16} color="#0d9488" />
                            <Text>{item}</Text>
                          </Space>
                        </DesktopList.Item>
                      )}
                      split={false}
                    />
                  </Col>
                </Row>
              </div>
            )}
          </Col>
          <Col xs={24} md={8}>
            {doctor.subSpecialties.length > 0 && (
              <DesktopCard bordered style={{ borderRadius: 8 }}>
                <Text strong style={{ display: 'block', marginBottom: 16 }}>Special Interests</Text>
                <Space size={[0, 8]} wrap>
                  {doctor.subSpecialties.map((s: string) => <Tag key={s} style={{ margin: 0, marginRight: 8 }}>{s}</Tag>)}
                </Space>
              </DesktopCard>
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
              <DesktopButton type="link" size="small">Get Directions</DesktopButton>
            </div>
          </Col>
        </Row>
      )
    }
  ]

  return (
    <div style={{ padding: '40px 24px', maxWidth: 1200, margin: '0 auto' }}>
      {/* Profile Header */}
      <DesktopCard bordered style={{ borderRadius: 12, marginBottom: 40 }} styles={{ body: { padding: 30 } }}>
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
      </DesktopCard>

      <Row gutter={40}>
        <Col span={24}>
          {/* Booking Section */}
          <DesktopCard bordered style={{ borderRadius: 12, marginBottom: 50 }} id="book-appointment" styles={{ body: { padding: 32 } }}>
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
                    <DesktopButton icon={<IconChevronLeft size={16} />} disabled={!canGoBack} onClick={handlePrevWeek} />
                    <Text strong>{format(currentStart, 'MMMM yyyy')}</Text>
                    <DesktopButton icon={<IconChevronRight size={16} />} onClick={handleNextWeek} />
                  </Space>
                </div>

                <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 4 }}>
                  {days.map((day: AvailabilityDay, index: number) => {
                    const isSelected = selectedDateIndex === index
                    const d = new Date(day.date)
                    return (
                      <DesktopCard
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
                        styles={{ body: { padding: 8, textAlign: 'center' } }}
                        onClick={() => { setSelectedDateIndex(index); setSelectedSlot(null); }}
                      >
                        <Text style={{ fontSize: 12, color: isSelected ? '#0d9488' : 'rgba(0,0,0,0.45)', textTransform: 'uppercase', fontWeight: 700, display: 'block' }}>
                          {d.toLocaleDateString(APP_LOCALE, { weekday: 'short' })}
                        </Text>
                        <Text strong style={{ fontSize: 18, color: isSelected ? '#0d9488' : undefined }}>{d.getDate()}</Text>
                      </DesktopCard>
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
                          <DesktopButton
                            key={slot.startsAt}
                            type={isSelected ? 'primary' : 'default'}
                            onClick={() => !isPast && setSelectedSlot(slot)}
                            disabled={isPast}
                            style={isPast ? { textDecoration: 'line-through' } : {}}
                            block
                          >
                            {slotDate.toLocaleTimeString(APP_LOCALE, { hour: '2-digit', minute: '2-digit' })}
                          </DesktopButton>
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
                  <DesktopButton
                    type="primary"
                    size="large"
                    block
                    onClick={handleBook}
                    loading={isBooking}
                    disabled={!selectedSlot || isBooking}
                  >
                    Confirm Booking
                  </DesktopButton>
                  <Text type="secondary" style={{ fontSize: 12, textAlign: 'center', display: 'block' }}>No payment required to book.</Text>
                </div>
              )}
            </div>
          </DesktopCard>

          {/* Details Tabs */}
          <Tabs defaultActiveKey="about" items={tabItems} size="large" />
        </Col>
      </Row>
    </div>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export default function DoctorProfilePage(props: PageProps) {
  const isMobile = useIsMobile()

  if (isMobile) {
    return <MobileDoctorProfile {...props} />
  }

  return <DesktopDoctorProfile {...props} />
}
