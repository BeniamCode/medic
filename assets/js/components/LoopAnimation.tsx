import { useEffect, useRef } from 'react'
import * as THREE from 'three'
import gsap from 'gsap'

const LOOP_COUNT = 20
const LOOP_RADIUS = 3

export function LoopAnimation() {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const animationFrameRef = useRef<number>()
  const timelinesRef = useRef<Array<gsap.core.Tween | gsap.core.Timeline>>([])

  useEffect(() => {
    const container = containerRef.current
    if (!container) return

    const scene = new THREE.Scene()
    scene.background = new THREE.Color('#062324')

    const camera = new THREE.PerspectiveCamera(
      40,
      container.clientWidth / container.clientHeight,
      0.1,
      100
    )
    camera.position.set(0, 0, 12)

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false })
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5))
    renderer.setSize(container.clientWidth, container.clientHeight)
    container.appendChild(renderer.domElement)

    const textureLoader = new THREE.TextureLoader()
    const matcap = textureLoader.load('/images/loop-matcap.jpg')
    const material = new THREE.MeshMatcapMaterial({ matcap })
    const geometry = new THREE.BoxGeometry(1, 0.2, 1)

    const ringGroup = new THREE.Group()
    scene.add(ringGroup)

    const segments: THREE.Mesh[] = []
    for (let index = 0; index < LOOP_COUNT; index++) {
      const angle = (index / LOOP_COUNT) * Math.PI * 2
      const mesh = new THREE.Mesh(geometry, material)
      mesh.position.set(
        Math.cos(angle) * LOOP_RADIUS,
        Math.sin(angle) * LOOP_RADIUS,
        0
      )
      mesh.rotation.z = angle
      ringGroup.add(mesh)
      segments.push(mesh)
    }

    const render = () => {
      renderer.render(scene, camera)
      animationFrameRef.current = requestAnimationFrame(render)
    }
    render()

    const loopTween = gsap.to(
      segments.map((segment) => segment.rotation),
      {
        y: `+=${Math.PI * 2}`,
        duration: 6,
        ease: 'none',
        repeat: -1
      }
    )
    const groupTween = gsap.to(ringGroup.rotation, {
      z: Math.PI * 2,
      duration: 24,
      ease: 'none',
      repeat: -1
    })
    timelinesRef.current = [loopTween, groupTween]

    const handleResize = () => {
      if (!container) return
      const { clientWidth, clientHeight } = container
      renderer.setSize(clientWidth, clientHeight)
      camera.aspect = clientWidth / Math.max(clientHeight, 1)
      camera.updateProjectionMatrix()
    }
    window.addEventListener('resize', handleResize)

    return () => {
      if (animationFrameRef.current) {
        cancelAnimationFrame(animationFrameRef.current)
      }
      timelinesRef.current.forEach((tween) => tween.kill())
      window.removeEventListener('resize', handleResize)
      geometry.dispose()
      material.dispose()
      matcap.dispose()
      renderer.dispose()
      container.removeChild(renderer.domElement)
    }
  }, [])

  return <div ref={containerRef} style={{ width: '100%', height: '100%' }} />
}
