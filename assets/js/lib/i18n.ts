import i18next, { type i18n as I18nInstance } from 'i18next'
import { initReactI18next } from 'react-i18next'

import type { SharedAppProps } from '@/types/app'

let instance: I18nInstance | null = null
let initialized = false

const buildResources = (payload: SharedAppProps['i18n']) => {
  return {
    [payload.locale]: Object.entries(payload.translations).reduce<Record<string, object>>(
      (acc, [namespace, entries]) => {
        acc[namespace] = entries
        return acc
      },
      {}
    )
  }
}

export const ensureI18n = async (payload: SharedAppProps['i18n']) => {
  if (!instance) {
    instance = i18next.createInstance()
  }

  if (!initialized) {
    await instance.use(initReactI18next).init({
      resources: buildResources(payload),
      lng: payload.locale,
      fallbackLng: payload.default_locale,
      ns: Object.keys(payload.translations),
      defaultNS: 'default',
      interpolation: { escapeValue: false }
    })
    initialized = true
    return instance
  }

  const resources = buildResources(payload)

  Object.entries(resources).forEach(([locale, namespaces]) => {
    Object.entries(namespaces).forEach(([ns, bundle]) => {
      instance?.addResourceBundle(locale, ns, bundle, true, true)
    })
  })

  await instance?.changeLanguage(payload.locale)
  return instance
}

export const getI18n = () => instance
