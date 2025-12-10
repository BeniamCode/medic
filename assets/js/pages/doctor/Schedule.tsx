import { Button, Card, Group, Modal, NumberInput, Select, Stack, Switch, Table, Text, TextInput, Title } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { useForm } from '@mantine/form'
import { router } from '@inertiajs/react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

type Rule = {
  id: string
  day_of_week: number
  start_time: string
  end_time: string
  break_start?: string | null
  break_end?: string | null
  slot_duration_minutes: number
  is_active: boolean
}

type Appointment = {
  id: string
  starts_at: string
  status: string
  patient: { first_name: string; last_name: string }
}

type PageProps = AppPageProps<{
  availability_rules: Rule[]
  upcoming_appointments: Appointment[]
}>

const dayOptions = [
  { value: '1', label: 'Monday' },
  { value: '2', label: 'Tuesday' },
  { value: '3', label: 'Wednesday' },
  { value: '4', label: 'Thursday' },
  { value: '5', label: 'Friday' },
  { value: '6', label: 'Saturday' },
  { value: '7', label: 'Sunday' }
]

const DoctorSchedulePage = ({ app, auth, availability_rules, upcoming_appointments }: PageProps) => {
  const { t } = useTranslation('default')
  const [opened, { open, close }] = useDisclosure(false)

  const form = useForm({
    initialValues: {
      id: '',
      day_of_week: '1',
      start_time: '09:00',
      end_time: '17:00',
      break_start: '',
      break_end: '',
      slot_duration_minutes: 30,
      is_active: true
    }
  })

  const handleEdit = (rule?: Rule) => {
    form.setValues({
      id: rule?.id || '',
      day_of_week: String(rule?.day_of_week || 1),
      start_time: rule?.start_time || '09:00',
      end_time: rule?.end_time || '17:00',
      break_start: rule?.break_start || '',
      break_end: rule?.break_end || '',
      slot_duration_minutes: rule?.slot_duration_minutes || 30,
      is_active: rule?.is_active ?? true
    })
    open()
  }

  const handleDelete = (rule: Rule) => {
    router.delete(`/doctor/schedule/${rule.id}`, { preserveScroll: true })
  }

  const submit = (values: typeof form.values) => {
    router.post('/doctor/schedule', { rule: values }, { preserveScroll: true })
    close()
  }

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="xl">
        <Group justify="space-between">
          <div>
            <Title order={2}>{t('doctor.schedule.title', 'Manage schedule')}</Title>
            <Text c="dimmed">{t('doctor.schedule.subtitle', 'Set your weekly availability')}</Text>
          </div>
          <Button onClick={() => handleEdit()}>{t('doctor.schedule.new_rule', 'Add rule')}</Button>
        </Group>

        <Card withBorder padding="lg" radius="lg">
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
              {availability_rules.map((rule) => (
                <Table.Tr key={rule.id} opacity={rule.is_active ? 1 : 0.5}>
                  <Table.Td>{dayOptions.find((d) => d.value === String(rule.day_of_week))?.label}</Table.Td>
                  <Table.Td>
                    <Text fw={600}>
                      {rule.start_time} - {rule.end_time}
                    </Text>
                    {rule.break_start && rule.break_end && (
                      <Text size="xs" c="dimmed">
                        {t('doctor.schedule.break', 'Break')}: {rule.break_start} - {rule.break_end}
                      </Text>
                    )}
                  </Table.Td>
                  <Table.Td>
                    <Badge color={rule.is_active ? 'green' : 'gray'}>
                      {rule.is_active ? t('doctor.schedule.active', 'Active') : t('doctor.schedule.off', 'Off')}
                    </Badge>
                  </Table.Td>
                  <Table.Td>
                    <Group gap="xs">
                      <Button variant="light" size="xs" onClick={() => handleEdit(rule)}>
                        {t('doctor.schedule.edit', 'Edit')}
                      </Button>
                      {rule.id && (
                        <Button variant="subtle" color="red" size="xs" onClick={() => handleDelete(rule)}>
                          {t('doctor.schedule.delete', 'Delete')}
                        </Button>
                      )}
                    </Group>
                  </Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </Card>

        <Card withBorder padding="lg" radius="lg">
          <Title order={4}>{t('doctor.schedule.upcoming', 'Upcoming appointments')}</Title>
          <Stack gap="md" mt="md">
            {upcoming_appointments.length === 0 ? (
              <Text c="dimmed">{t('doctor.schedule.no_upcoming', 'No upcoming visits')}</Text>
            ) : (
              upcoming_appointments.map((appt) => (
                <Card key={appt.id} withBorder padding="md">
                  <Group justify="space-between">
                    <div>
                      <Text fw={600}>
                        {appt.patient.first_name} {appt.patient.last_name}
                      </Text>
                      <Text size="sm" c="dimmed">
                        {new Date(appt.starts_at).toLocaleString()}
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

      <Modal opened={opened} onClose={close} title={t('doctor.schedule.edit_rule', 'Edit rule')}>
        <form onSubmit={form.onSubmit(submit)} className="space-y-4">
          <Select label={t('doctor.schedule.day', 'Day')} data={dayOptions} {...form.getInputProps('day_of_week')} />
          <Group grow>
            <TextInput label={t('doctor.schedule.start', 'Start')} {...form.getInputProps('start_time')} />
            <TextInput label={t('doctor.schedule.end', 'End')} {...form.getInputProps('end_time')} />
          </Group>
          <Group grow>
            <TextInput label={t('doctor.schedule.break_start', 'Break start')} {...form.getInputProps('break_start')} />
            <TextInput label={t('doctor.schedule.break_end', 'Break end')} {...form.getInputProps('break_end')} />
          </Group>
          <NumberInput label={t('doctor.schedule.duration', 'Slot duration (min)')} {...form.getInputProps('slot_duration_minutes')} min={10} step={5} />
          <Switch label={t('doctor.schedule.active', 'Active')} {...form.getInputProps('is_active', { type: 'checkbox' })} />
          <Button type="submit" fullWidth>
            {t('doctor.schedule.save', 'Save')}
          </Button>
        </form>
      </Modal>
    </PublicLayout>
  )
}

export default DoctorSchedulePage
