import { useMemo, useState, useEffect, useRef, type FormEvent } from 'react'
import { Link, router } from '@inertiajs/react'
import { useDebouncedValue } from '@mantine/hooks'
import {
  Button,
  Card,
  Col,
  Row,
  Input,
  Select,
  Slider,
  Typography,
  Tag,
  Avatar,
  Rate,
  Space,
  Empty
} from 'antd'
import { IconFilter, IconMapPin, IconSearch } from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import DoctorMap from '@/components/Map'

const { Title, Text } = Typography
const { Search: AntSearch } = Input

export type SearchDoctor = {
  id: string
  firstName: string
  lastName: string
  specialtyName: string | null
  city: string | null
  address: string | null
  rating: number | null
  reviewCount: number | null
  consultationFee: number | null
  verified: boolean
  profileImageUrl: string | null
  locationLat: number | null
  locationLng: number | null
}

type SearchProps = AppPageProps<{
  doctors: SearchDoctor[]
  specialties: { id: string; name: string; slug: string }[]
  filters: { query: string; specialty: string | null }
  meta: { total: number; source: string }
}>

const createParams = (query: string, specialty: string) => {
  const params = new URLSearchParams()
  if (query) params.set('q', query)
  if (specialty) params.set('specialty', specialty)
  return params
}

export default function SearchPage({ app, auth, doctors = [], specialties = [], filters = { query: '', specialty: '' }, meta }: SearchProps) {
  const { t } = useTranslation('default')

  // Initialize state
  const [query, setQuery] = useState(filters?.query || '')
  const [debouncedQuery] = useDebouncedValue(query, 300)
  const [specialty, setSpecialty] = useState(filters?.specialty ?? '')
  const [mapHeight, setMapHeight] = useState(250)
  const [focusedDoctorId, setFocusedDoctorId] = useState<string | null>(null)

  const isMounted = useRef(false)

  // Live Search Effect
  useEffect(() => {
    if (!isMounted.current) {
      isMounted.current = true
      return
    }

    router.get(`/search?${createParams(debouncedQuery, specialty).toString()}`, undefined, {
      preserveScroll: true,
      preserveState: true,
      replace: true
    })
  }, [debouncedQuery, specialty])

  const specialtyOptions = useMemo(
    () =>
      specialties.map((item: { name: string; slug: string }) => ({
        value: item.slug,
        label: item.name
      })),
    [specialties]
  )

  const submit = (value: string) => {
    // Instant trigger (ignores debounce)
    router.get(`/search?${createParams(value, specialty).toString()}`, undefined, {
      preserveScroll: true,
      preserveState: true
    })
  }

  const handleDoctorClick = (id: string) => {
    setFocusedDoctorId(id)
    setMapHeight(500) // Auto-expand map
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <div>
      {/* 1. Map Container - Top */}
      <div
        style={{
          height: mapHeight,
          width: '100%',
          backgroundColor: '#f5f5f5',
          transition: 'height 0.3s ease',
          zIndex: 10,
          position: 'relative',
          overflow: 'hidden'
        }}
        onMouseEnter={() => setMapHeight(500)}
        onMouseLeave={() => setMapHeight(250)}
      >
        <DoctorMap doctors={doctors} height={500} expanded={mapHeight === 500} focusedDoctorId={focusedDoctorId} />
      </div>

      {/* 2. Google-Style Search Bar - Centered */}
      <div style={{ maxWidth: 960, margin: '-24px auto 0', padding: '0 24px', position: 'relative', zIndex: 20 }}>
        <Card style={{ borderRadius: 24, padding: 8 }} bodyStyle={{ padding: 0 }} bordered shadow="always">
          <AntSearch
            placeholder={t('search.placeholder', 'Search doctors, clinics, specialties, etc.')}
            size="large"
            bordered={false}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onSearch={submit}
            enterButton={
              <Button type="primary" shape="round" icon={<IconSearch size={18} />}>
                Search
              </Button>
            }
          />
        </Card>
      </div>


      <div style={{ maxWidth: 1200, margin: '50px auto', padding: '0 24px' }}>
        <Row gutter={40}>
          {/* Sidebar Filters */}
          <Col xs={24} md={6}>
            <div style={{ position: 'sticky', top: 20, display: 'flex', flexDirection: 'column', gap: 24 }}>
              <Card bordered style={{ borderRadius: 12 }}>
                <Space align="center" style={{ marginBottom: 16 }}>
                  <div style={{ padding: 6, borderRadius: 6, backgroundColor: '#e6fffa', color: '#0d9488' }}>
                    <IconFilter size={16} />
                  </div>
                  <Text strong>Filters</Text>
                </Space>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                  <div>
                    <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13 }}>Specialty</Text>
                    <Select
                      placeholder="Any specialty"
                      options={specialtyOptions}
                      value={specialty}
                      onChange={(value) => setSpecialty(value || '')}
                      allowClear
                      showSearch
                      style={{ width: '100%' }}
                    />
                  </div>

                  {/* RangeSlider */}
                  <div>
                    <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13 }}>Price Range</Text>
                    <Slider
                      range
                      min={0}
                      max={300}
                      step={10}
                      defaultValue={[0, 300]}
                      tooltip={{ formatter: (val) => `€${val}`, open: false }}
                    />
                  </div>
                </div>
              </Card>
            </div>
          </Col>

          {/* Results */}
          <Col xs={24} md={18}>
            <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
              <Text strong style={{ fontSize: 16 }}> {meta.total} specialists found</Text>
              <Tag>Sort by: Best Match</Tag>
            </Row>

            <Row gutter={[24, 24]}>
              {doctors.map((doctor: SearchDoctor) => {
                const isFocused = focusedDoctorId === doctor.id
                return (
                  <Col xs={24} sm={12} md={8} key={doctor.id}>
                    <Card
                      hoverable
                      style={{
                        borderRadius: 12,
                        borderColor: isFocused ? '#13c2c2' : undefined,
                        transition: 'all 0.2s',
                        overflow: 'hidden'
                      }}
                      bodyStyle={{ padding: 16 }}
                      cover={
                        <div style={{ height: 200, backgroundColor: '#f0f0f0', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <Avatar
                            src={doctor.profileImageUrl}
                            size={120}
                          >
                            {doctor.firstName?.charAt(0) || 'D'}
                          </Avatar>
                        </div>
                      }
                      onClick={() => handleDoctorClick(doctor.id)}
                    >

                      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                          <div>
                            <Title level={4} style={{ margin: 0, fontSize: 16, lineHeight: 1.2 }}>
                              {doctor.firstName} {doctor.lastName}
                            </Title>
                            {doctor.verified && <Tag color="cyan" style={{ marginTop: 4, marginRight: 0 }}>Verified</Tag>}
                          </div>
                          <Rate disabled defaultValue={doctor.rating || 0} style={{ fontSize: 12 }} />
                        </div>

                        <Text type="secondary" style={{ fontSize: 13 }}>{doctor.specialtyName || 'General Practitioner'}</Text>

                        <Space size={4} style={{ color: 'rgba(0,0,0,0.45)' }}>
                          <IconMapPin size={16} />
                          <Text type="secondary" style={{ fontSize: 13 }}>{doctor.city || 'Online'}</Text>
                        </Space>

                        <Row justify="space-between" align="middle" style={{ marginTop: 8 }}>
                          <Text strong style={{ fontSize: 18, color: '#0d9488' }}>
                            {doctor.consultationFee ? `€${doctor.consultationFee}` : 'Ask'}
                          </Text>
                          <Link href={`/doctors/${doctor.id}`}>
                            <Button size="small" onClick={(e: any) => e.stopPropagation()}>
                              View Profile
                            </Button>
                          </Link>
                        </Row>
                      </div>
                    </Card>
                  </Col>
                )
              })}
            </Row>

            {doctors.length === 0 && (
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '50px 0' }}>
                <div style={{ padding: 20, borderRadius: 20, backgroundColor: '#f5f5f5', marginBottom: 16 }}>
                  <IconSearch size={30} color="#999" />
                </div>
                <Title level={4} style={{ margin: 0 }}>No doctors found</Title>
                <Text type="secondary">Try adjusting your filters</Text>
              </div>
            )}
          </Col>
        </Row>
      </div>
    </div>
  )
}
