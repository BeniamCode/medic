import {
  Badge,
  Button,
  Card,
  Divider,
  Group,
  Modal,
  NumberInput,
  Paper,
  Select,
  Stack,
  Switch,
  Table,
  Text,
  TextInput,
  Title
} from '@mantine/core'
import { DateInput } from '@mantine/dates'
import { useDisclosure } from '@mantine/hooks'
import { router } from '@inertiajs/react'
import { useEffect, useMemo, useState } from 'react'
import { useForm, Controller } from 'react-hook-form'
import { useMutation } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'

import type { AppPageProps } from '@/types/app'

const dayOptions = [
  { value: '1', label: 'Monday' },
  { value: '2', label: 'Tuesday' },
  { value: '3', label: 'Wednesday' },
  { value: '4', label: 'Thursday' },
  { value: '5', label: 'Friday' },
  { value: '6', label: 'Saturday' },
  { value: '7', label: 'Sunday' }
]

const dayLabel = (value?: string) => dayOptions.find((d) => d.value === value)?.label || '—'

const DEFAULT_VALUES = {
  id: '',
  day_of_week: '1',
  start_time: '09:00',
  end_time: '17:00',
  break_start: '',
  break_end: '',
  slot_duration_minutes: 30,
  is_active: true
}

type Rule = {
  id: string
  dayOfWeek: number
  startTime: string
  endTime: string
  breakStart?: string | null
  breakEnd?: string | null
  slotDurationMinutes: number
  isActive: boolean
}

type Appointment = {
  id: string
  startsAt: string
  status: string
  patient: { firstName: string; lastName: string }
}

type PageProps = AppPageProps<{
  availabilityRules: Rule[]
  upcomingAppointments: Appointment[]
}>

const DoctorSchedulePage = ({ availabilityRules, upcomingAppointments }: PageProps) => {
  const { t } = useTranslation('default')
  const [opened, { open, close }] = useDisclosure(false)
  const [selectedDay, setSelectedDay] = useState('1')
  const [modalDay, setModalDay] = useState('1')
  const [copySource, setCopySource] = useState<string | null>(null)
  const [dayOffDate, setDayOffDate] = useState<Date | null>(null)

  const groupedRules = useMemo(() => {
    const map: Record<string, Rule> = {}
    availabilityRules.forEach((rule) => {
      map[String(rule.dayOfWeek)] = rule
    })
    return map
  }, [availabilityRules])

  const initialDrafts = useMemo(() => {
    const result: Record<string, typeof DEFAULT_VALUES> = {}
    dayOptions.forEach((option) => {
      const rule = groupedRules[option.value]
      if (rule) {
        result[option.value] = {
          id: rule.id,
          day_of_week: option.value,
          start_time: rule.startTime,
          end_time: rule.endTime,
          break_start: rule.breakStart || '',
          break_end: rule.breakEnd || '',
          slot_duration_minutes: rule.slotDurationMinutes,
          is_active: rule.isActive
        }
      } else {
        result[option.value] = { ...DEFAULT_VALUES, day_of_week: option.value }
      }
    })
    return result
  }, [groupedRules])

  const [draftRules, setDraftRules] = useState(initialDrafts)

  useEffect(() => {
    setDraftRules(initialDrafts)
  }, [initialDrafts])

  const form = useForm<typeof DEFAULT_VALUES>({
    defaultValues: draftRules[modalDay] || { ...DEFAULT_VALUES, day_of_week: modalDay }
  })

  const { control, handleSubmit, reset, watch, getValues } = form

  useEffect(() => {
    reset(draftRules[modalDay] || { ...DEFAULT_VALUES, day_of_week: modalDay })
  }, [modalDay, draftRules, reset])

  useEffect(() => {
    if (!opened) return
    const subscription = watch((value) => {
      syncDraft(modalDay, value as typeof DEFAULT_VALUES)
    })
    return () => subscription.unsubscribe()
  }, [watch, opened, modalDay])

  const syncDraft = (day: string, values: typeof DEFAULT_VALUES) => {
    setDraftRules((prev) => ({
      ...prev,
      [day]: { ...values, day_of_week: day }
    }))
  }

  const openModalForDay = (day: string) => {
    setModalDay(day)
    setCopySource(null)
    reset(draftRules[day] || { ...DEFAULT_VALUES, day_of_week: day })
    open()
  }

  const handleCopyFrom = (sourceDay: string) => {
    const source = draftRules[sourceDay]
    if (!source) {
      reset({ ...DEFAULT_VALUES, day_of_week: modalDay })
      syncDraft(modalDay, { ...DEFAULT_VALUES, day_of_week: modalDay })
      return
    }

    const copied = {
      ...source,
      id: '',
      day_of_week: modalDay
    }
    reset(copied)
    syncDraft(modalDay, copied)
  }

  const saveRuleMutation = useMutation({
    mutationFn: async (values: typeof DEFAULT_VALUES) =>
      await new Promise<void>((resolve, reject) => {
        router.post('/doctor/schedule', { rule: values }, {
          preserveScroll: true,
          onSuccess: () => resolve(),
          onError: () => reject(new Error('Failed to save rule'))
        })
      }),
    onSuccess: () => close()
  })

  const blockDayMutation = useMutation({
    mutationFn: async (isoDate: string) =>
      await new Promise<void>((resolve, reject) => {
        router.post('/doctor/schedule/day_off', { exception: { date: isoDate } }, {
          preserveScroll: true,
          onSuccess: () => resolve(),
          onError: () => reject(new Error('Failed to block day'))
        })
      }),
    onSuccess: () => setDayOffDate(null)
  })

  const submit = (values: typeof DEFAULT_VALUES) => {
    saveRuleMutation.mutate(values)
  }

  const dayOffPreview = dayOffDate ? dayOffDate.toLocaleDateString() : '—'
  const startTime = watch('start_time')
  const endTime = watch('end_time')
  const duration = watch('slot_duration_minutes')
  const previewSlots = useMemo(
    () => buildPreviewSlots(startTime, endTime, duration),
    [startTime, endTime, duration]
  )

  const handleBlockDay = () => {
    if (!dayOffDate) return
    blockDayMutation.mutate(dayOffDate.toISOString().slice(0, 10))
  }

  return (
    <Stack gap="xl" p="xl">
      <Stack gap="xl">
        <Group justify="space-between">
          <div>
            <Title order={2}>{t('doctor.schedule.title', 'Manage schedule')}</Title>
            <Text c="dimmed">{t('doctor.schedule.subtitle', 'Set your weekly availability')}</Text>
          </div>
          <Group>
            <Button onClick={() => openModalForDay(selectedDay)}>{t('doctor.schedule.new_rule', 'Add rule')}</Button>
          </Group>
        </Group>

        <Card withBorder padding="lg" radius="lg">
          <Stack gap="sm">
            <Group justify="space-between" align="flex-start">
              <div>
                <Text fw={600}>{t('doctor.schedule.day_off.title', 'Need a day off?')}</Text>
                <Text size="sm" c="dimmed">
                  {t('doctor.schedule.day_off.helper', 'Pick a date to block the entire day. Patients will see it as unavailable.')}
                </Text>
              </div>
              <Badge color="gray" variant="light">
                {t('doctor.schedule.day_off.preview', 'Selected date:')} {dayOffPreview}
              </Badge>
            </Group>
            <Group grow>
              <DateInput value={dayOffDate} onChange={setDayOffDate} label={t('doctor.schedule.day_off.date', 'Select date')} placeholder="2025-04-12" />
              <Button
                variant="light"
                onClick={handleBlockDay}
                disabled={!dayOffDate || blockDayMutation.isPending}
                loading={blockDayMutation.isPending}
                radius="md"
              >
                {t('doctor.schedule.day_off.block', 'Block day')}
              </Button>
            </Group>
          </Stack>
        </Card>

        <Card withBorder padding="lg" radius="lg">
          <Group gap="xs" wrap="wrap" mb="md">
            {dayOptions.map((option) => (
              <Button
                key={option.value}
                variant={selectedDay === option.value ? 'filled' : 'light'}
                color="teal"
                size="sm"
                radius="xl"
                onClick={() => setSelectedDay(option.value)}
              >
                {option.label}
              </Button>
            ))}
          </Group>

          <Table>
            <Table.Thead>
              <Table.Tr>
                <Table.Th>{t('doctor.schedule.day', 'Day')}</Table.Th>
                <Table.Th>{t('doctor.schedule.hours', 'Hours')}</Table.Th>
                <Table.Th>{t('doctor.schedule.status', 'Status')}</Table.Th>
                <Table.Th></Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {dayOptions.map((option) => {
                const rule = groupedRules[option.value]
                return (
                  <Table.Tr key={option.value} opacity={rule?.isActive === false ? 0.5 : 1}>
                    <Table.Td>{option.label}</Table.Td>
                    <Table.Td>
                      {rule ? (
                        <Stack gap={4}>
                          <Text fw={600}>
                            {rule.startTime} - {rule.endTime}
                          </Text>
                          {rule.breakStart && rule.breakEnd && (
                            <Text size="xs" c="dimmed">
                              {t('doctor.schedule.break', 'Break')}: {rule.breakStart} - {rule.breakEnd}
                            </Text>
                          )}
                        </Stack>
                      ) : (
                        <Text c="dimmed">{t('doctor.schedule.no_rule', 'No rule yet')}</Text>
                      )}
                    </Table.Td>
                    <Table.Td>
                      {rule ? (
                        <Badge color={rule.isActive ? 'green' : 'gray'}>
                          {rule.isActive ? t('doctor.schedule.active', 'Active') : t('doctor.schedule.off', 'Off')}
                        </Badge>
                      ) : (
                        <Badge color="gray" variant="light">
                          {t('doctor.schedule.off', 'Off')}
                        </Badge>
                      )}
                    </Table.Td>
                    <Table.Td>
                      <Group gap="xs">
                        <Button variant="light" size="xs" onClick={() => openModalForDay(option.value)}>
                          {rule ? t('doctor.schedule.edit', 'Edit') : t('doctor.schedule.add', 'Add')}
                        </Button>
                        {rule?.id && (
                          <Button variant="subtle" color="red" size="xs" onClick={() => router.delete(`/doctor/schedule/${rule.id}`)}>
                            {t('doctor.schedule.delete', 'Delete')}
                          </Button>
                        )}
                      </Group>
                    </Table.Td>
                  </Table.Tr>
                )
              })}
            </Table.Tbody>
          </Table>
        </Card>

        <Card withBorder padding="lg" radius="lg">
          <Title order={4}>{t('doctor.schedule.upcoming', 'Upcoming appointments')}</Title>
          <Stack gap="md" mt="md">
            {upcomingAppointments.length === 0 ? (
              <Text c="dimmed">{t('doctor.schedule.no_upcoming', 'No upcoming visits')}</Text>
            ) : (
              upcomingAppointments.map((appt) => (
                <Card key={appt.id} withBorder padding="md">
                  <Group justify="space-between">
                    <div>
                      <Text fw={600}>
                        {appt.patient.firstName} {appt.patient.lastName}
                      </Text>
                      <Text size="sm" c="dimmed">
                        {new Date(appt.startsAt).toLocaleString()}
                      </Text>
                    </div>
                    <Badge>{appt.status}</Badge>
                  </Group>
                </Card>
              ))
            )}
          </Stack>
        </Card>
      </Stack>

      <Modal
        opened={opened}
        onClose={close}
        title={`${dayLabel(modalDay)} · ${t('doctor.schedule.edit_rule', 'Availability rule')}`}
        radius="lg"
        size="70%"
        overlayProps={{ blur: 3, opacity: 0.55 }}
      >
        <form onSubmit={handleSubmit(submit)}>
          <Stack gap="lg">
            <div>
              <Title order={4}>{t('doctor.schedule.modal_heading', 'Define your working window')}</Title>
              <Text size="sm" c="dimmed">
                {t('doctor.schedule.modal_subheading', 'Patients will only see slots inside this window with the buffer and break you configure below.')}
              </Text>
            </div>

            <Stack gap="xs">
              <Text size="sm" fw={600}>
                {t('doctor.schedule.day', 'Day tabs')}
              </Text>
              <Group gap="xs" wrap="wrap">
                {dayOptions.map((option) => (
                  <Button
                    key={option.value}
                    size="xs"
                    radius="xl"
                    variant={modalDay === option.value ? 'filled' : 'light'}
                    color="teal"
                    onClick={() => {
                      syncDraft(modalDay, getValues())
                      setModalDay(option.value)
                      reset(draftRules[option.value] || { ...DEFAULT_VALUES, day_of_week: option.value })
                    }}
                  >
                    {option.label}
                  </Button>
                ))}
              </Group>
            </Stack>

            <Group gap="sm" align="center">
              <Select
                data={dayOptions.filter((option) => option.value !== modalDay)}
                placeholder={t('doctor.schedule.copy_placeholder', 'Copy settings from…')}
                value={copySource}
                onChange={(val) => {
                  setCopySource(val)
                  if (val) handleCopyFrom(val)
                }}
                withinPortal
                className="max-w-xs"
              />
              <Text size="sm" c="dimmed">
                {t('doctor.schedule.copy_helper', 'Use this to reuse another day’s configuration.')}
              </Text>
            </Group>

            <Group grow align="flex-start">
              <Paper
                withBorder
                radius="md"
                p="md"
                className="flex-1"
                style={{ backgroundColor: 'var(--mantine-color-teal-0)', borderColor: 'var(--mantine-color-teal-2)' }}
              >
                <Group justify="space-between" align="center">
                  <div>
                    <Text fw={600}>{t('doctor.schedule.active', 'Available this day')}</Text>
                    <Text size="sm" c="dimmed">
                      {t('doctor.schedule.active_helper', 'Toggle off if you take this weekday off every week.')}
                    </Text>
                  </div>
                  <Controller
                    control={control}
                    name="is_active"
                    render={({ field }) => (
                      <Switch size="md" color="teal" checked={field.value} onChange={(event) => field.onChange(event.currentTarget.checked)} />
                    )}
                  />
                </Group>
              </Paper>
              <Controller
                control={control}
                name="slot_duration_minutes"
                render={({ field }) => (
                  <NumberInput
                    label={t('doctor.schedule.duration', 'Slot duration (minutes)')}
                    min={10}
                    step={5}
                    value={field.value}
                    onChange={(value) => field.onChange(typeof value === 'number' ? value : 0)}
                  />
                )}
              />
            </Group>

            <Group grow>
              <Controller
                control={control}
                name="start_time"
                render={({ field }) => (
                  <TextInput
                    label={t('doctor.schedule.start', 'Clinic opens at')}
                    type="time"
                    value={field.value}
                    onChange={(event) => field.onChange(event.currentTarget.value)}
                  />
                )}
              />
              <Controller
                control={control}
                name="end_time"
                render={({ field }) => (
                  <TextInput
                    label={t('doctor.schedule.end', 'Clinic closes at')}
                    type="time"
                    value={field.value}
                    onChange={(event) => field.onChange(event.currentTarget.value)}
                  />
                )}
              />
            </Group>

            <Paper withBorder radius="md" p="md">
              <Group justify="space-between" align="flex-start">
                <div>
                  <Text fw={600}>{t('doctor.schedule.break', 'Midday break')}</Text>
                  <Text size="sm" c="dimmed">
                    {t('doctor.schedule.break_helper', 'Optional buffer to block lunch or rounds. Leave blank if not needed.')}
                  </Text>
                </div>
                <Switch
                  checked={Boolean(getValues('break_start') || getValues('break_end'))}
                  onChange={(event) => {
                    if (!event.currentTarget.checked) {
                      reset({ ...getValues(), break_start: '', break_end: '' })
                    }
                  }}
                />
              </Group>
              <Divider my="sm" />
              <Group grow>
                <Controller
                  control={control}
                  name="break_start"
                  render={({ field }) => (
                    <TextInput
                      label={t('doctor.schedule.break_start', 'Starts')}
                      type="time"
                      value={field.value}
                      onChange={(event) => field.onChange(event.currentTarget.value)}
                    />
                  )}
                />
                <Controller
                  control={control}
                  name="break_end"
                  render={({ field }) => (
                    <TextInput
                      label={t('doctor.schedule.break_end', 'Ends')}
                      type="time"
                      value={field.value}
                      onChange={(event) => field.onChange(event.currentTarget.value)}
                    />
                  )}
                />
              </Group>
            </Paper>

            <Paper withBorder radius="md" p="md">
              <Stack gap="xs">
                <Text fw={600}>{t('doctor.schedule.preview', 'Slot preview')}</Text>
                <Text size="sm" c="dimmed">
                  {t('doctor.schedule.preview_helper', 'Patients will see these exact start times when booking this day.')}
                </Text>
                <Group gap="xs" wrap="wrap">
                  {previewSlots.length === 0 ? (
                    <Text size="sm" c="dimmed">
                      {t('doctor.schedule.preview_empty', 'Adjust start/end time to see slots.')}
                    </Text>
                  ) : (
                    previewSlots.map((slot) => (
                      <Button key={slot} size="xs" variant="light" color="gray">
                        {slot}
                      </Button>
                    ))
                  )}
                </Group>
              </Stack>
            </Paper>

            <Button type="submit" size="md" radius="md" loading={saveRuleMutation.isPending} disabled={saveRuleMutation.isPending}>
              {t('doctor.schedule.save', 'Save rule')}
            </Button>
          </Stack>
        </form>
      </Modal>
    </Stack>
  )
}

export default DoctorSchedulePage

const buildPreviewSlots = (start?: string, finish?: string, duration?: number) => {
  if (!start || !finish || !duration) {
    return []
  }

  const startMinutes = timeToMinutes(start)
  const endMinutes = timeToMinutes(finish)

  if (startMinutes === null || endMinutes === null || endMinutes <= startMinutes) {
    return []
  }

  const slots: string[] = []
  let pointer = startMinutes

  while (pointer + duration <= endMinutes) {
    slots.push(minutesToTime(pointer))
    pointer += duration
  }

  return slots
}

const timeToMinutes = (value: string) => {
  if (!value) return null
  const [h, m] = value.split(':').map((val) => Number(val))
  if (Number.isNaN(h) || Number.isNaN(m)) {
    return null
  }
  return h * 60 + m
}

const minutesToTime = (mins: number) => {
  const hours = Math.floor(mins / 60)
  const minutes = mins % 60
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`
}
