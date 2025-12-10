import {
  Badge,
  Box,
  Button,
  Card,
  Divider,
  Group,
  List,
  SimpleGrid,
  Stack,
  Text,
  Textarea,
  Title
} from '@mantine/core'
import { IconCalendar, IconClock, IconPhoneCall, IconShieldCheck, IconVideo } from '@tabler/icons-react'
import type { ReactElement } from 'react'
import { useState } from 'react'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

export type DoctorProfile = {
  id: string
  full_name: string
  first_name: string
  last_name: string
  title: string | null
  pronouns: string | null
  rating: number | null
  review_count: number
  verified: boolean
  profile_image_url: string | null
  specialty: { name: string; slug: string } | null
  city: string | null
  address: string | null
  hospital_affiliation: string | null
  years_of_experience: number | null
  bio: string | null
  sub_specialties: string[]
  clinical_procedures: string[]
  conditions_treated: string[]
  languages: string[]
  awards: string[]
  telemedicine_available: boolean
  consultation_fee: number | null
  next_available_slot: string | null
}

type AvailabilityDay = {
  date: string
  slots: { starts_at: string; ends_at: string; status: string }[]
}

type PageProps = AppPageProps<{ doctor: DoctorProfile; availability: AvailabilityDay[] }>

const Section = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <Stack gap="xs">
    <Title order={3} fz="lg">
      {title}
    </Title>
    {children}
  </Stack>
)

const ListPills = ({ items }: { items: string[] }) => (
  <Group gap="xs" wrap="wrap">
    {items.map((item) => (
      <Badge key={item} color="gray" variant="light">
        {item}
      </Badge>
    ))}
  </Group>
)

const DoctorProfilePage = ({ doctor, app, auth, availability }: PageProps) => {
  const { t } = useTranslation('default')
  const [selectedDateIndex, setSelectedDateIndex] = useState(0)
  const [selectedSlot, setSelectedSlot] = useState<{ starts_at: string; ends_at: string } | null>(null)
  const [notes, setNotes] = useState('')
  const [appointmentType, setAppointmentType] = useState<'in_person' | 'telemedicine'>(
    doctor.telemedicine_available ? 'in_person' : 'in_person'
  )

  const heroSubtitle = [doctor.specialty?.name, doctor.city].filter(Boolean).join(' · ')
  const heroImage =
    doctor.profile_image_url ||
    'https://images.unsplash.com/photo-1504435093301-4ff3a67e78f4?auto=format&fit=crop&w=500&q=80'

  const nextSlot = doctor.next_available_slot
    ? new Intl.DateTimeFormat(app.locale, {
        weekday: 'short',
        month: 'short',
        day: 'numeric'
      }).format(new Date(doctor.next_available_slot))
    : null

  const days = availability || []
  const currentDay = days[selectedDateIndex]

  const handleBook = () => {
    if (!selectedSlot) return
    if (!auth.authenticated) {
      router.visit('/login')
      return
    }

    router.post(`/doctors/${doctor.id}/book`, {
      booking: {
        starts_at: selectedSlot.starts_at,
        ends_at: selectedSlot.ends_at,
        appointment_type: appointmentType,
        notes
      }
    })
  }

  return (
    <Stack gap="xl">
      <Card shadow="lg" radius="xl" padding="xl">
        <Group align="flex-start" gap="xl">
          <Box w={{ base: '100%', sm: 200 }}>
            <img src={heroImage} alt={doctor.full_name} className="w-full rounded-2xl object-cover" />
          </Box>
          <Stack gap="sm" flex={1}>
            <Group gap="sm" align="center">
              <Title order={1} fz={{ base: 'xl', sm: 36 }}>
                {doctor.title || t('doctor.title_default', 'Dr.')} {doctor.full_name}
              </Title>
              {doctor.verified && (
                <Badge leftSection={<IconShieldCheck size={14} />} color="teal" variant="light">
                  {t('doctor.verified', 'Verified')}
                </Badge>
              )}
            </Group>
            <Text c="dimmed">{heroSubtitle}</Text>
            <Group gap="md">
              <Text fw={600}>{doctor.rating ? doctor.rating.toFixed(1) : '—'}</Text>
              <Text c="dimmed">({doctor.review_count || 0} {t('doctor.reviews', 'reviews')})</Text>
            </Group>
            <Group gap="md">
              {doctor.consultation_fee && (
                <Text fw={600}>€{doctor.consultation_fee.toFixed(0)} {t('doctor.fee', 'per visit')}</Text>
              )}
              {doctor.telemedicine_available && (
                <Badge color="indigo" leftSection={<IconVideo size={14} />}>
                  {t('doctor.telemedicine', 'Video visits')}
                </Badge>
              )}
            </Group>
            <Group gap="md">
              <Button href="#booking" component="a" leftSection={<IconCalendar size={16} />}>
                {t('doctor.cta.book', 'Book appointment')}
              </Button>
              <Button variant="light" leftSection={<IconPhoneCall size={16} />}>
                {t('doctor.cta.contact', 'Contact clinic')}
              </Button>
            </Group>
            {nextSlot && (
              <Badge variant="light" color="green">
                {t('doctor.next_slot', { defaultValue: 'Next available {{slot}}', slot: nextSlot })}
              </Badge>
            )}
          </Stack>
        </Group>
      </Card>

      <Card withBorder padding="lg" radius="lg" id="booking">
        <Stack gap="lg">
          <Title order={3}>{t('doctor.booking.title', 'Book an appointment')}</Title>
          {days.length === 0 ? (
            <Text c="dimmed">{t('doctor.booking.no_availability', 'No availability published')}</Text>
          ) : (
            <>
              <Group gap="sm" wrap="wrap">
                {days.map((day, index) => (
                  <Button
                    key={day.date}
                    variant={index === selectedDateIndex ? 'filled' : 'light'}
                    onClick={() => {
                      setSelectedDateIndex(index)
                      setSelectedSlot(null)
                    }}
                  >
                    {new Date(day.date).toLocaleDateString(app.locale, {
                      weekday: 'short',
                      month: 'short',
                      day: 'numeric'
                    })}
                  </Button>
                ))}
              </Group>
              <Group gap="sm" wrap="wrap">
                {currentDay?.slots.filter((slot) => slot.status === 'free').length ? (
                  currentDay?.slots
                    .filter((slot) => slot.status === 'free')
                    .map((slot) => (
                      <Button
                        key={slot.starts_at}
                        variant={selectedSlot?.starts_at === slot.starts_at ? 'filled' : 'outline'}
                        onClick={() => setSelectedSlot(slot)}
                        leftSection={<IconClock size={14} />}
                      >
                        {new Date(slot.starts_at).toLocaleTimeString(app.locale, {
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </Button>
                    ))
                ) : (
                  <Text c="dimmed">{t('doctor.booking.no_slots', 'No slots available')}</Text>
                )}
              </Group>
              {doctor.telemedicine_available && (
                <Group>
                  <Button
                    variant={appointmentType === 'in_person' ? 'filled' : 'light'}
                    onClick={() => setAppointmentType('in_person')}
                  >
                    {t('doctor.booking.in_person', 'In person')}
                  </Button>
                  <Button
                    variant={appointmentType === 'telemedicine' ? 'filled' : 'light'}
                    onClick={() => setAppointmentType('telemedicine')}
                  >
                    {t('doctor.booking.telemed', 'Telemedicine')}
                  </Button>
                </Group>
              )}
              <Textarea
                label={t('doctor.booking.notes', 'Notes for doctor')}
                placeholder={t('doctor.booking.notes_placeholder', 'Symptoms, expectations…')}
                value={notes}
                onChange={(event) => setNotes(event.currentTarget.value)}
              />
              <Button onClick={handleBook} disabled={!selectedSlot}>
                {t('doctor.booking.submit', 'Request appointment')}
              </Button>
            </>
          )}
        </Stack>
      </Card>

      <SimpleLayout doctor={doctor} t={t} />
    </Stack>
  )
}

const SimpleLayout = ({
  doctor,
  t
}: {
  doctor: DoctorProfile
  t: ReturnType<typeof useTranslation>['t']
}) => (
  <SimpleGrid cols={{ base: 1, lg: 2 }} spacing="xl">
    <Stack gap="xl">
      <Section title={t('doctor.sections.about', 'About')}>
        <Text>{doctor.bio || t('doctor.sections.about_placeholder', 'Bio coming soon')}</Text>
      </Section>

      {doctor.sub_specialties.length > 0 && (
        <Section title={t('doctor.sections.focus', 'Sub-specialties')}>
          <ListPills items={doctor.sub_specialties} />
        </Section>
      )}

      {doctor.clinical_procedures.length > 0 && (
        <Section title={t('doctor.sections.procedures', 'Procedures')}>
          <List spacing="xs">
            {doctor.clinical_procedures.map((item) => (
              <List.Item key={item}>{item}</List.Item>
            ))}
          </List>
        </Section>
      )}

      {doctor.conditions_treated.length > 0 && (
        <Section title={t('doctor.sections.conditions', 'Conditions treated')}>
          <List spacing="xs">
            {doctor.conditions_treated.map((item) => (
              <List.Item key={item}>{item}</List.Item>
            ))}
          </List>
        </Section>
      )}
    </Stack>

    <Stack gap="xl">
      <Card withBorder padding="lg" radius="lg">
        <Stack gap="sm">
          <Text fw={600}>{t('doctor.sections.details', 'Practice details')}</Text>
          <Divider />
          {doctor.hospital_affiliation && (
            <Text>{doctor.hospital_affiliation}</Text>
          )}
          {doctor.address && <Text>{doctor.address}</Text>}
          {doctor.languages.length > 0 && (
            <Text c="dimmed">
              {t('doctor.sections.languages', 'Languages')}: {doctor.languages.join(', ')}
            </Text>
          )}
          {doctor.years_of_experience && (
            <Text c="dimmed">
              {doctor.years_of_experience}+ {t('doctor.sections.experience', 'years experience')}
            </Text>
          )}
        </Stack>
      </Card>

      {doctor.awards.length > 0 && (
        <Card withBorder padding="lg" radius="lg">
          <Section title={t('doctor.sections.awards', 'Awards & recognition')}>
            <List spacing="xs">
              {doctor.awards.map((award) => (
                <List.Item key={award}>{award}</List.Item>
              ))}
            </List>
          </Section>
        </Card>
      )}
    </Stack>
  </SimpleGrid>
)

DoctorProfilePage.layout = (page: ReactElement<PageProps>) => (
  <PublicLayout app={page.props.app} auth={page.props.auth}>
    {page}
  </PublicLayout>
)

export default DoctorProfilePage
