import { useEffect, useRef } from 'react'
import * as THREE from 'three'
import gsap from 'gsap'

const SEGMENTS = 20
const RADIUS = 3

export function LoopAnimation() {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const animationFrame = useRef<number>()
  const tweensRef = useRef<gsap.core.Tween[]>([])

  useEffect(() => {
    const container = containerRef.current
    if (!container) return

    const scene = new THREE.Scene()
    const camera = new THREE.PerspectiveCamera(
      40,
      container.clientWidth / container.clientHeight,
      0.1,
      100
    )
    camera.position.z = 12

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true })
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.setSize(container.clientWidth, container.clientHeight)
    renderer.setClearColor(0x000000, 0)
    container.appendChild(renderer.domElement)

    const loader = new THREE.TextureLoader()
    const matcap = loader.load('/images/loop-matcap.jpg')
    const material = new THREE.MeshMatcapMaterial({ matcap })
    const geometry = new THREE.BoxGeometry(1, 0.2, 1)

    const ring = new THREE.Group()
    scene.add(ring)

    const segments: THREE.Mesh[] = []
    for (let i = 0; i < SEGMENTS; i++) {
      const angle = (i / SEGMENTS) * Math.PI * 2
      const pivot = new THREE.Group()
      pivot.rotation.z = angle
      pivot.position.set(
        Math.cos(angle) * RADIUS,
        Math.sin(angle) * RADIUS,
        0
      )

      const mesh = new THREE.Mesh(geometry, material)
      pivot.add(mesh)
      ring.add(pivot)
      segments.push(mesh)
    }

    const render = () => {
      renderer.render(scene, camera)
      animationFrame.current = requestAnimationFrame(render)
    }
    render()

    const segmentTween = gsap.to(
      segments.map((segment) => segment.rotation),
      {
        y: `+=${Math.PI * 2}`,
        duration: 12,
        ease: 'none',
        repeat: -1
      }
    )
    const ringTween = gsap.to(ring.rotation, {
      z: Math.PI * 2,
      duration: 48,
      ease: 'none',
      repeat: -1
    })
    tweensRef.current = [segmentTween, ringTween]

    const handleResize = () => {
      if (!container) return
      const { clientWidth, clientHeight } = container
      renderer.setSize(clientWidth, clientHeight)
      camera.aspect = clientWidth / Math.max(clientHeight, 1)
      camera.updateProjectionMatrix()
    }
    window.addEventListener('resize', handleResize)

    return () => {
      animationFrame.current && cancelAnimationFrame(animationFrame.current)
      window.removeEventListener('resize', handleResize)
      tweensRef.current.forEach((tween) => tween.kill())
      geometry.dispose()
      material.dispose()
      matcap.dispose()
      renderer.dispose()
      container.removeChild(renderer.domElement)
    }
  }, [])

  return <div ref={containerRef} style={{ width: '100%', height: '100%' }} />
}
