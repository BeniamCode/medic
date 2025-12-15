import { useMemo, useState, useEffect, useRef } from 'react'
import { Link, router } from '@inertiajs/react'
import { useDebouncedValue } from '@mantine/hooks'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import DoctorMap from '@/components/Map'
import { useIsMobile } from '@/lib/device'

// Desktop Ant Design imports
import {
  Button as DesktopButton,
  Card as DesktopCard,
  Col,
  Row,
  Input as DesktopInput,
  Select as DesktopSelect,
  Slider,
  Typography,
  Tag,
  Space,
  Switch as DesktopSwitch,
  Divider
} from 'antd'
import { HeartOutlined, FilterOutlined, UnorderedListOutlined, EnvironmentOutlined } from '@ant-design/icons'
import { IconFilter, IconMapPin, IconSearch } from '@tabler/icons-react'

// Mobile Ant Design imports
import {
  Button as MobileButton,
  Card as MobileCard,
  SearchBar,
  Popup,
  List,
  Switch as MobileSwitch,
  Selector,
  FloatingBubble,
  Tag as MobileTag,
  Tabs,
  Empty
} from 'antd-mobile'
import { FilterOutline, LocationOutline } from 'antd-mobile-icons'

const { Title, Text } = Typography

export type SearchDoctor = {
  id: string
  firstName: string
  lastName: string
  specialtyName: string | null
  city: string | null
  address: string | null
  rating: number | null
  reviewCount: number | null
  appreciationCount: number | null
  consultationFee: number | null
  verified: boolean
  profileImageUrl: string | null
  locationLat: number | null
  locationLng: number | null
}

type SearchProps = AppPageProps<{
  doctors: SearchDoctor[]
  specialties: { id: string; name: string; slug: string }[]
  cities: string[]
  insurances: string[]
  filters: {
    query: string
    specialty: string | null
    city: string | null
    max_price: number | null
    telemedicine: boolean
    insurance: string | null
  }
  meta: { total: number; source: string }
}>

const createParams = (
  query: string,
  specialty: string,
  city: string,
  maxPrice: number | null,
  telemedicine: boolean,
  insurance: string
) => {
  const params = new URLSearchParams()
  if (query) params.set('q', query)
  if (specialty) params.set('specialty', specialty)
  if (city) params.set('city', city)
  if (typeof maxPrice === 'number') params.set('max_price', String(maxPrice))
  if (telemedicine) params.set('telemedicine', 'true')
  if (insurance) params.set('insurance', insurance)
  return params
}

// =============================================================================
// MOBILE COMPONENTS (using antd-mobile)
// =============================================================================

function MobileDoctorCard({ doctor, onClick }: { doctor: SearchDoctor; onClick: () => void }) {
  return (
    <MobileCard
      onClick={onClick}
      style={{
        borderRadius: 12,
        marginBottom: 12,
        boxShadow: '0 1px 4px rgba(0,0,0,0.08)'
      }}
    >
      <div style={{ display: 'flex', gap: 12 }}>
        {/* Avatar */}
        <div
          style={{
            width: 72,
            height: 72,
            borderRadius: 12,
            backgroundColor: '#f5f5f5',
            flexShrink: 0,
            overflow: 'hidden'
          }}
        >
          {doctor.profileImageUrl ? (
            <img
              src={doctor.profileImageUrl}
              alt={`${doctor.firstName ?? ''} ${doctor.lastName ?? ''}`.trim() || 'Doctor'}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            />
          ) : (
            <div
              style={{
                width: '100%',
                height: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 28,
                fontWeight: 600,
                color: 'rgba(0,0,0,0.35)',
                background: 'linear-gradient(135deg, #e6fffa 0%, #b2f5ea 100%)'
              }}
            >
              {doctor.firstName?.charAt(0) || 'D'}
            </div>
          )}
        </div>

        {/* Info */}
        <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
            <span style={{ fontSize: 15, fontWeight: 600, color: '#333' }}>
              Dr. {doctor.firstName} {doctor.lastName}
            </span>
            {doctor.verified && (
              <MobileTag color="primary" fill="outline" style={{ fontSize: 10, padding: '0 4px' }}>✓</MobileTag>
            )}
          </div>

          <span style={{ fontSize: 13, color: '#666', marginBottom: 4 }}>
            {doctor.specialtyName || 'General Practitioner'}
          </span>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: '#999' }}>
              <LocationOutline fontSize={14} />
              <span style={{ fontSize: 12 }}>{doctor.city || 'Online'}</span>
            </div>

            <span style={{ fontSize: 16, fontWeight: 600, color: '#0d9488' }}>
              {doctor.consultationFee ? `€${doctor.consultationFee}` : 'Ask'}
            </span>
          </div>
        </div>

        {/* Appreciation Badge */}
        {(doctor.appreciationCount || 0) > 0 && (
          <div style={{ position: 'absolute', top: 12, right: 12 }}>
            <MobileTag color="danger" fill="outline" style={{ fontSize: 11 }}>
              ♥ {doctor.appreciationCount}
            </MobileTag>
          </div>
        )}
      </div>
    </MobileCard>
  )
}

function MobileSearchPage({
  doctors,
  specialties,
  cities,
  filters,
  meta,
  query,
  setQuery,
  specialty,
  setSpecialty,
  city,
  setCity,
  telemedicineOnly,
  setTelemedicineOnly,
  submit,
  clearFilters
}: {
  doctors: SearchDoctor[]
  specialties: { id: string; name: string; slug: string }[]
  cities: string[]
  filters: SearchProps['filters']
  meta: { total: number; source: string }
  query: string
  setQuery: (v: string) => void
  specialty: string
  setSpecialty: (v: string) => void
  city: string
  setCity: (v: string) => void
  telemedicineOnly: boolean
  setTelemedicineOnly: (v: boolean) => void
  submit: (v: string) => void
  clearFilters: () => void
}) {
  const { t } = useTranslation('default')
  const [filterPopupVisible, setFilterPopupVisible] = useState(false)
  const [activeTab, setActiveTab] = useState('list')

  const specialtyOptions = useMemo(
    () => specialties.map((item) => ({ value: item.slug, label: item.name })),
    [specialties]
  )

  const cityOptions = useMemo(
    () => cities.map((name) => ({ value: name, label: name })),
    [cities]
  )

  const activeFilterCount = [specialty, city, telemedicineOnly].filter(Boolean).length

  const handleDoctorClick = (id: string) => {
    router.visit(`/doctors/${id}`)
  }

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5' }}>
      {/* Sticky Header */}
      <div
        style={{
          position: 'sticky',
          top: 0,
          zIndex: 100,
          backgroundColor: '#fff',
          padding: '12px 16px',
          paddingTop: 'max(12px, env(safe-area-inset-top))',
          borderBottom: '1px solid #eee'
        }}
      >
        <SearchBar
          placeholder={t('search.placeholder', 'Search doctors...')}
          value={query}
          onChange={setQuery}
          onSearch={submit}
          style={{
            '--border-radius': '8px',
            '--background': '#f5f5f5',
            '--height': '40px',
            '--font-size': '16px'
          } as React.CSSProperties}
        />

        {/* Tabs for List/Map */}
        <Tabs
          activeKey={activeTab}
          onChange={setActiveTab}
          style={{ marginTop: 12 }}
        >
          <Tabs.Tab title="List" key="list" />
          <Tabs.Tab title="Map" key="map" />
        </Tabs>
      </div>

      {/* Results Count */}
      <div style={{ padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ fontSize: 14, color: '#666' }}>
          {meta.total} doctors found
        </span>
      </div>

      {/* Content */}
      {activeTab === 'map' ? (
        <div style={{ height: 'calc(100vh - 160px)' }}>
          <DoctorMap doctors={doctors} height="100%" expanded focusedDoctorId={null} />
        </div>
      ) : (
        <div style={{ padding: '0 16px', paddingBottom: 100 }}>
          {doctors.length === 0 ? (
            <Empty
              style={{ padding: '60px 0' }}
              description="No doctors found"
            />
          ) : (
            doctors.map((doctor) => (
              <MobileDoctorCard
                key={doctor.id}
                doctor={doctor}
                onClick={() => handleDoctorClick(doctor.id)}
              />
            ))
          )}
        </div>
      )}

      {/* Floating Filter Button */}
      <FloatingBubble
        axis="xy"
        magnetic="x"
        style={{
          '--initial-position-bottom': '24px',
          '--initial-position-right': '24px',
          '--edge-distance': '24px',
          '--background': '#0d9488',
          '--size': '56px'
        }}
        onClick={() => setFilterPopupVisible(true)}
      >
        <div style={{ position: 'relative' }}>
          <FilterOutline fontSize={24} color="#fff" />
          {activeFilterCount > 0 && (
            <div
              style={{
                position: 'absolute',
                top: -8,
                right: -8,
                width: 18,
                height: 18,
                borderRadius: '50%',
                backgroundColor: '#ff4d4f',
                color: '#fff',
                fontSize: 11,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              {activeFilterCount}
            </div>
          )}
        </div>
      </FloatingBubble>

      {/* Filter Popup */}
      <Popup
        visible={filterPopupVisible}
        onMaskClick={() => setFilterPopupVisible(false)}
        position="bottom"
        bodyStyle={{
          borderTopLeftRadius: 16,
          borderTopRightRadius: 16,
          minHeight: '60vh',
          maxHeight: '85vh',
          paddingBottom: 'env(safe-area-inset-bottom)'
        }}
      >
        <div style={{ padding: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
            <h3 style={{ margin: 0, fontSize: 18, fontWeight: 600 }}>Filters</h3>
            <MobileButton size="small" fill="none" onClick={clearFilters}>
              Clear all
            </MobileButton>
          </div>

          <List>
            <List.Item
              title="Specialty"
              description={specialty || 'All specialties'}
              onClick={() => { }}
              arrow
            >
              <Selector
                columns={1}
                options={[{ value: '', label: 'All specialties' }, ...specialtyOptions]}
                value={[specialty]}
                onChange={(v) => setSpecialty(v[0] || '')}
                style={{ marginTop: 8 }}
              />
            </List.Item>

            <List.Item
              title="City"
              description={city || 'All cities'}
              onClick={() => { }}
              arrow
            >
              <Selector
                columns={2}
                options={[{ value: '', label: 'All' }, ...cityOptions]}
                value={[city]}
                onChange={(v) => setCity(v[0] || '')}
                style={{ marginTop: 8 }}
              />
            </List.Item>

            <List.Item
              title="Telemedicine only"
              extra={
                <MobileSwitch
                  checked={telemedicineOnly}
                  onChange={setTelemedicineOnly}
                />
              }
            />
          </List>

          <MobileButton
            block
            color="primary"
            size="large"
            style={{ marginTop: 24 }}
            onClick={() => setFilterPopupVisible(false)}
          >
            Show {meta.total} results
          </MobileButton>
        </div>
      </Popup>
    </div>
  )
}

// =============================================================================
// DESKTOP COMPONENTS (using regular antd)
// =============================================================================

function DesktopDoctorCard({ doctor, isFocused, onClick }: { doctor: SearchDoctor; isFocused: boolean; onClick: () => void }) {
  return (
    <DesktopCard
      hoverable
      style={{
        borderRadius: 12,
        borderColor: isFocused ? '#13c2c2' : undefined,
        transition: 'all 0.2s',
        overflow: 'hidden'
      }}
      styles={{ body: { padding: 16 } }}
      cover={
        <div style={{ height: 200, backgroundColor: '#f0f0f0' }}>
          {doctor.profileImageUrl ? (
            <img
              src={doctor.profileImageUrl}
              alt={`${doctor.firstName ?? ''} ${doctor.lastName ?? ''}`.trim() || 'Doctor'}
              style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
            />
          ) : (
            <div
              style={{
                width: '100%',
                height: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 64,
                lineHeight: 1,
                fontWeight: 600,
                color: 'rgba(0,0,0,0.35)'
              }}
            >
              {doctor.firstName?.charAt(0) || 'D'}
            </div>
          )}
        </div>
      }
      onClick={onClick}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <Title level={4} style={{ margin: 0, fontSize: 16, lineHeight: 1.2 }}>
              {doctor.firstName} {doctor.lastName}
            </Title>
            {doctor.verified && <Tag color="cyan" style={{ marginTop: 4, marginRight: 0 }}>Verified</Tag>}
          </div>
          {(doctor.appreciationCount || 0) > 0 && (
            <Tag color="magenta" icon={<HeartOutlined />} style={{ margin: 0 }}>
              {doctor.appreciationCount}
            </Tag>
          )}
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
            <DesktopButton size="small" onClick={(e: any) => e.stopPropagation()}>
              View Profile
            </DesktopButton>
          </Link>
        </Row>
      </div>
    </DesktopCard>
  )
}

function DesktopSearchPage({
  doctors,
  specialties,
  cities,
  insurances,
  filters,
  meta,
  query,
  setQuery,
  specialty,
  setSpecialty,
  city,
  setCity,
  insurance,
  setInsurance,
  telemedicineOnly,
  setTelemedicineOnly,
  maxPrice,
  setMaxPrice,
  submit,
  clearFilters
}: {
  doctors: SearchDoctor[]
  specialties: { id: string; name: string; slug: string }[]
  cities: string[]
  insurances: string[]
  filters: SearchProps['filters']
  meta: { total: number; source: string }
  query: string
  setQuery: (v: string) => void
  specialty: string
  setSpecialty: (v: string) => void
  city: string
  setCity: (v: string) => void
  insurance: string
  setInsurance: (v: string) => void
  telemedicineOnly: boolean
  setTelemedicineOnly: (v: boolean) => void
  maxPrice: number | null
  setMaxPrice: (v: number | null) => void
  submit: (v: string) => void
  clearFilters: () => void
}) {
  const { t } = useTranslation('default')
  const [mapHeight, setMapHeight] = useState(250)
  const [focusedDoctorId, setFocusedDoctorId] = useState<string | null>(null)
  const [showMoreFilters, setShowMoreFilters] = useState(false)

  const specialtyOptions = useMemo(
    () => specialties.map((item) => ({ value: item.slug, label: item.name })),
    [specialties]
  )

  const cityOptions = useMemo(
    () => cities.map((name) => ({ value: name, label: name })),
    [cities]
  )

  const insuranceOptions = useMemo(
    () => insurances.map((name) => ({ value: name, label: name })),
    [insurances]
  )

  const handleDoctorClick = (id: string) => {
    setFocusedDoctorId(id)
    setMapHeight(500)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  return (
    <div>
      {/* Map Container */}
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
      >
        <DoctorMap doctors={doctors} height={500} expanded={mapHeight === 500} focusedDoctorId={focusedDoctorId} />
      </div>

      {/* Search Bar */}
      <div style={{ maxWidth: 960, margin: '-24px auto 0', padding: '0 24px', position: 'relative', zIndex: 20 }}>
        <DesktopCard
          style={{ borderRadius: 24, padding: 8 }}
          styles={{ body: { padding: 0 } }}
          variant="outlined"
        >
          <Space.Compact style={{ width: '100%' }}>
            <DesktopInput
              placeholder={t('search.placeholder', 'Search doctors, clinics, specialties, etc.')}
              size="large"
              variant="borderless"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onPressEnter={() => submit(query)}
            />
            <DesktopButton type="primary" size="large" onClick={() => submit(query)} icon={<IconSearch size={18} />}>
              Search
            </DesktopButton>
          </Space.Compact>
        </DesktopCard>
      </div>

      <div style={{ maxWidth: 1200, margin: '50px auto', padding: '0 24px' }}>
        <Row gutter={40}>
          {/* Sidebar Filters */}
          <Col xs={24} md={6}>
            <div style={{ position: 'sticky', top: 20, display: 'flex', flexDirection: 'column', gap: 24 }}>
              <DesktopCard variant="outlined" style={{ borderRadius: 12 }}>
                <Space align="center" style={{ marginBottom: 16 }}>
                  <div style={{ padding: 6, borderRadius: 6, backgroundColor: '#e6fffa', color: '#0d9488' }}>
                    <IconFilter size={16} />
                  </div>
                  <Text strong>Filters</Text>
                </Space>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                  <div>
                    <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13 }}>Specialty</Text>
                    <DesktopSelect
                      placeholder="Select specialty"
                      options={specialtyOptions}
                      value={specialty || undefined}
                      onChange={(value) => setSpecialty(value || '')}
                      allowClear
                      showSearch
                      style={{ width: '100%' }}
                    />
                  </div>

                  <div>
                    <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13 }}>City</Text>
                    <DesktopSelect
                      placeholder="Select city"
                      options={cityOptions}
                      value={city || undefined}
                      onChange={(value) => setCity(value || '')}
                      allowClear
                      showSearch
                      style={{ width: '100%' }}
                    />
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <Text strong style={{ display: 'block', fontSize: 13 }}>Telemedicine available</Text>
                      <Text type="secondary" style={{ fontSize: 12 }}>Only show doctors offering telehealth</Text>
                    </div>
                    <DesktopSwitch checked={telemedicineOnly} onChange={(checked) => setTelemedicineOnly(checked)} />
                  </div>

                  <Divider style={{ margin: '4px 0' }} />

                  <DesktopButton
                    type="default"
                    onClick={() => setShowMoreFilters((v) => !v)}
                    style={{ width: '100%' }}
                  >
                    {showMoreFilters ? 'Less filters' : 'More filters'}
                  </DesktopButton>

                  {showMoreFilters && (
                    <>
                      <div>
                        <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13 }}>Insurance</Text>
                        <DesktopSelect
                          placeholder="Select insurance"
                          options={insuranceOptions}
                          value={insurance || undefined}
                          onChange={(value) => setInsurance(value || '')}
                          allowClear
                          showSearch
                          style={{ width: '100%' }}
                        />
                      </div>

                      <div>
                        <Text strong style={{ display: 'block', marginBottom: 8, fontSize: 13 }}>Max price</Text>
                        <Slider
                          min={30}
                          max={300}
                          step={10}
                          value={maxPrice ?? 300}
                          onChange={(value) => {
                            const v = Array.isArray(value) ? value[0] : value
                            setMaxPrice(v >= 300 ? null : v)
                          }}
                          tooltip={{ formatter: (val) => `€${val}`, open: false }}
                        />
                        <Text type="secondary" style={{ fontSize: 12 }}>
                          {typeof maxPrice === 'number' ? `≤ €${maxPrice}` : 'Any price'}
                        </Text>
                      </div>

                      <DesktopButton
                        type="default"
                        onClick={clearFilters}
                        style={{ width: '100%' }}
                      >
                        Clear filters
                      </DesktopButton>
                    </>
                  )}
                </div>
              </DesktopCard>
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
                    <DesktopDoctorCard
                      doctor={doctor}
                      isFocused={isFocused}
                      onClick={() => handleDoctorClick(doctor.id)}
                    />
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

// =============================================================================
// MAIN COMPONENT - Routes to Mobile or Desktop
// =============================================================================

export default function SearchPage({ app, auth, doctors = [], specialties = [], cities = [], insurances = [], filters, meta }: SearchProps) {
  const isMobile = useIsMobile()

  // Shared state
  const [query, setQuery] = useState(filters?.query || '')
  const [debouncedQuery] = useDebouncedValue(query, 300)
  const [specialty, setSpecialty] = useState(filters?.specialty ?? '')
  const [city, setCity] = useState(filters?.city ?? '')
  const [insurance, setInsurance] = useState(filters?.insurance ?? '')
  const [telemedicineOnly, setTelemedicineOnly] = useState(Boolean(filters?.telemedicine))
  const [maxPrice, setMaxPrice] = useState<number | null>(typeof filters?.max_price === 'number' ? filters.max_price : null)

  const isMounted = useRef(false)

  // Live Search Effect
  useEffect(() => {
    if (!isMounted.current) {
      isMounted.current = true
      return
    }

    router.get(
      `/search?${createParams(debouncedQuery, specialty, city, maxPrice, telemedicineOnly, insurance).toString()}`,
      undefined,
      {
        preserveScroll: true,
        preserveState: true,
        replace: true
      }
    )
  }, [debouncedQuery, specialty, city, maxPrice, telemedicineOnly, insurance])

  const submit = (value: string) => {
    router.get(`/search?${createParams(value, specialty, city, maxPrice, telemedicineOnly, insurance).toString()}`, undefined, {
      preserveScroll: true,
      preserveState: true
    })
  }

  const clearFilters = () => {
    setSpecialty('')
    setCity('')
    setInsurance('')
    setTelemedicineOnly(false)
    setMaxPrice(null)
  }

  // Render mobile or desktop version
  if (isMobile) {
    return (
      <MobileSearchPage
        doctors={doctors}
        specialties={specialties}
        cities={cities}
        filters={filters}
        meta={meta}
        query={query}
        setQuery={setQuery}
        specialty={specialty}
        setSpecialty={setSpecialty}
        city={city}
        setCity={setCity}
        telemedicineOnly={telemedicineOnly}
        setTelemedicineOnly={setTelemedicineOnly}
        submit={submit}
        clearFilters={clearFilters}
      />
    )
  }

  return (
    <DesktopSearchPage
      doctors={doctors}
      specialties={specialties}
      cities={cities}
      insurances={insurances}
      filters={filters}
      meta={meta}
      query={query}
      setQuery={setQuery}
      specialty={specialty}
      setSpecialty={setSpecialty}
      city={city}
      setCity={setCity}
      insurance={insurance}
      setInsurance={setInsurance}
      telemedicineOnly={telemedicineOnly}
      setTelemedicineOnly={setTelemedicineOnly}
      maxPrice={maxPrice}
      setMaxPrice={setMaxPrice}
      submit={submit}
      clearFilters={clearFilters}
    />
  )
}
