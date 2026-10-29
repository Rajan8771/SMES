import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { RoundedBox } from "@react-three/drei";
import * as THREE from "three";
import { modelFor, type Focus, type ModelId } from "../content";

const HOMES: Record<ModelId, [number, number, number]> = {
  phones: [1.05, 0.2, 0.35],
  audio: [2.75, 0.15, 0.1],
  camera: [2.05, -0.15, 1.0],
  care: [1.7, 1.15, -0.55],
};

function Paint({
  color,
  metalness = 0.28,
  roughness = 0.24,
}: {
  color: string;
  metalness?: number;
  roughness?: number;
}) {
  return (
    <meshPhysicalMaterial
      color={color}
      metalness={metalness}
      roughness={roughness}
      clearcoat={1}
      clearcoatRoughness={0.16}
    />
  );
}

function Handset({
  color,
  position,
  rotation,
}: {
  color: string;
  position: [number, number, number];
  rotation: [number, number, number];
}) {
  return (
    <group position={position} rotation={rotation}>
      <RoundedBox args={[0.7, 1.42, 0.08]} radius={0.1} smoothness={5}>
        <Paint color={color} metalness={0.42} roughness={0.18} />
      </RoundedBox>
      <RoundedBox args={[0.58, 1.24, 0.015]} radius={0.05} position={[0, 0, 0.048]}>
        <Paint color="#120814" metalness={0.15} roughness={0.12} />
      </RoundedBox>
      <RoundedBox args={[0.22, 0.08, 0.02]} radius={0.02} position={[0.16, 0.5, 0.06]}>
        <Paint color="#2a2418" metalness={0.7} roughness={0.25} />
      </RoundedBox>
      <mesh position={[0.12, 0.5, 0.075]} rotation={[Math.PI / 2, 0, 0]}>
        <cylinderGeometry args={[0.028, 0.028, 0.02, 16]} />
        <Paint color="#49d2ff" metalness={0.3} roughness={0.1} />
      </mesh>
    </group>
  );
}

function Phones() {
  return (
    <group>
      <Handset color="#1bd176" position={[-0.15, 0.05, 0]} rotation={[0.08, -0.45, 0.12]} />
      <Handset color="#ff4f9a" position={[0.55, -0.05, 0.25]} rotation={[0.05, -0.2, -0.18]} />
      <Handset color="#49d2ff" position={[0.15, 0.2, -0.35]} rotation={[-0.1, 0.35, 0.22]} />
    </group>
  );
}

function Audio() {
  return (
    <group>
      <RoundedBox args={[0.72, 0.28, 0.95]} radius={0.12} position={[0, -0.1, 0]}>
        <Paint color="#ffd23f" metalness={0.35} roughness={0.22} />
      </RoundedBox>
      <group position={[-0.42, 0.35, 0.15]} rotation={[0.4, 0.2, 0.6]}>
        <mesh>
          <sphereGeometry args={[0.16, 24, 24]} />
          <Paint color="#fff6ea" metalness={0.55} roughness={0.2} />
        </mesh>
        <mesh position={[0, -0.22, 0]}>
          <cylinderGeometry args={[0.045, 0.06, 0.28, 16]} />
          <Paint color="#1bd176" metalness={0.4} roughness={0.2} />
        </mesh>
      </group>
      <group position={[0.48, 0.42, -0.1]} rotation={[0.5, -0.3, -0.5]}>
        <mesh>
          <sphereGeometry args={[0.16, 24, 24]} />
          <Paint color="#fff6ea" metalness={0.55} roughness={0.2} />
        </mesh>
        <mesh position={[0, -0.22, 0]}>
          <cylinderGeometry args={[0.045, 0.06, 0.28, 16]} />
          <Paint color="#ff4f9a" metalness={0.4} roughness={0.2} />
        </mesh>
      </group>
    </group>
  );
}

function Camera() {
  return (
    <group rotation={[0.4, 0.5, 0.1]}>
      <RoundedBox args={[0.95, 0.95, 0.18]} radius={0.12} position={[0, 0, 0]}>
        <Paint color="#1a1024" metalness={0.55} roughness={0.28} />
      </RoundedBox>
      {[
        [-0.22, 0.22, "#49d2ff"],
        [0.22, 0.22, "#ffd23f"],
        [-0.22, -0.22, "#ff4f9a"],
      ].map(([x, y, color]) => (
        <group key={`${x}-${y}`} position={[Number(x), Number(y), 0.12]}>
          <mesh>
            <cylinderGeometry args={[0.16, 0.16, 0.08, 28]} />
            <Paint color="#0c0c12" metalness={0.8} roughness={0.15} />
          </mesh>
          <mesh position={[0, 0.05, 0]}>
            <cylinderGeometry args={[0.09, 0.09, 0.03, 24]} />
            <Paint color={String(color)} metalness={0.25} roughness={0.12} />
          </mesh>
        </group>
      ))}
    </group>
  );
}

function Care() {
  const ring = useRef<THREE.Group>(null);
  useFrame((state) => {
    if (ring.current) ring.current.rotation.z = state.clock.elapsedTime * 0.6;
  });
  return (
    <group>
      <mesh rotation={[Math.PI / 2, 0, 0]}>
        <cylinderGeometry args={[0.55, 0.55, 0.1, 40]} />
        <Paint color="#c9a6ff" metalness={0.35} roughness={0.22} />
      </mesh>
      <mesh position={[0, 0.08, 0]} rotation={[Math.PI / 2, 0, 0]}>
        <cylinderGeometry args={[0.16, 0.16, 0.06, 24]} />
        <Paint color="#1bd176" metalness={0.5} roughness={0.2} />
      </mesh>
      <group ref={ring} rotation={[Math.PI / 2.4, 0.2, 0]}>
        <mesh>
          <torusGeometry args={[0.85, 0.045, 12, 40]} />
          <Paint color="#ff5a1f" metalness={0.3} roughness={0.25} />
        </mesh>
      </group>
    </group>
  );
}

const MODELS: Record<ModelId, () => ReactNode> = {
  phones: Phones,
  audio: Audio,
  camera: Camera,
  care: Care,
};

function Cluster({
  id,
  focus,
  children,
}: {
  id: ModelId;
  focus: Focus;
  children: ReactNode;
}) {
  const ref = useRef<THREE.Group>(null);
  const smoothed = useRef(new THREE.Vector3(...HOMES[id]));
  const scale = useRef(1);

  useFrame((state, delta) => {
    const group = ref.current;
    if (!group) return;
    const solo = modelFor(focus) === id;
    const home = HOMES[id];
    const targetX = solo ? 2.15 : home[0];
    const targetY = solo ? 0.35 : home[1];
    const targetZ = solo ? 0.2 : home[2];
    const targetScale = focus === "all" ? 1 : solo ? 1.48 : 0.001;
    const k = 1 - Math.exp(-delta * 5);
    const point = smoothed.current;
    point.x += (targetX - point.x) * k;
    point.y += (targetY - point.y) * k;
    point.z += (targetZ - point.z) * k;
    scale.current += (targetScale - scale.current) * k;
    const bob =
      scale.current > 0.25
        ? Math.sin(state.clock.elapsedTime * 1.2 + home[0]) * 0.06
        : 0;
    group.position.set(point.x, point.y + bob, point.z);
    group.scale.setScalar(Math.max(scale.current, 0.001));
    group.visible = scale.current > 0.04;
  });

  return (
    <group ref={ref} position={HOMES[id]}>
      {children}
    </group>
  );
}

function Chips() {
  const colors = [
    "#ff5a1f",
    "#49d2ff",
    "#ffd23f",
    "#ff4f9a",
    "#8dff63",
    "#c9a6ff",
    "#ffffff",
    "#ff3b1f",
  ];
  return (
    <group>
      {colors.map((color, index) => {
        const angle = (index / colors.length) * Math.PI * 2;
        return (
          <mesh
            key={color}
            position={[
              2.05 + Math.cos(angle) * 1.55,
              0.45 + Math.sin(angle * 2) * 0.7,
              Math.sin(angle) * 1.05,
            ]}
          >
            <icosahedronGeometry args={[0.08 + (index % 3) * 0.02, 0]} />
            <Paint color={color} metalness={0.2} roughness={0.15} />
          </mesh>
        );
      })}
    </group>
  );
}

function Stage() {
  const texture = useMemo(() => {
    const canvas = document.createElement("canvas");
    canvas.width = 256;
    canvas.height = 256;
    const context = canvas.getContext("2d");
    if (!context) return null;
    const gradient = context.createRadialGradient(128, 128, 16, 128, 128, 128);
    gradient.addColorStop(0, "rgba(12, 4, 24, 0.48)");
    gradient.addColorStop(1, "rgba(12, 4, 24, 0)");
    context.fillStyle = gradient;
    context.fillRect(0, 0, 256, 256);
    const map = new THREE.CanvasTexture(canvas);
    map.colorSpace = THREE.SRGBColorSpace;
    return map;
  }, []);

  const rings = useRef<THREE.Group>(null);
  useFrame((state) => {
    if (rings.current) {
      rings.current.rotation.z = state.clock.elapsedTime * 0.12;
    }
  });

  return (
    <group position={[2.05, -0.72, 0]}>
      {texture && (
        <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.01, 0]}>
          <planeGeometry args={[7.5, 7.5]} />
          <meshBasicMaterial map={texture} transparent depthWrite={false} />
        </mesh>
      )}
      <group ref={rings} rotation={[-Math.PI / 2, 0, 0]}>
        <mesh>
          <ringGeometry args={[1.05, 1.55, 80]} />
          <meshBasicMaterial color="#ffd23f" side={THREE.DoubleSide} />
        </mesh>
        <mesh>
          <ringGeometry args={[1.62, 1.74, 80]} />
          <meshBasicMaterial color="#49d2ff" side={THREE.DoubleSide} />
        </mesh>
        <mesh>
          <ringGeometry args={[1.8, 2.05, 80]} />
          <meshBasicMaterial color="#ff4f9a" side={THREE.DoubleSide} />
        </mesh>
      </group>
    </group>
  );
}

function Rig({ focus }: { focus: Focus }) {
  const ref = useRef<THREE.Group>(null);
  const pointer = useRef({ x: 0, y: 0 });

  useEffect(() => {
    const onMove = (event: PointerEvent) => {
      pointer.current.x = (event.clientX / window.innerWidth) * 2 - 1;
      pointer.current.y = (event.clientY / window.innerHeight) * 2 - 1;
    };
    window.addEventListener("pointermove", onMove, { passive: true });
    return () => window.removeEventListener("pointermove", onMove);
  }, []);

  useFrame((state) => {
    const group = ref.current;
    if (!group) return;
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const wobble = reduce ? 0 : Math.sin(state.clock.elapsedTime * 0.45) * 0.16;
    group.rotation.y = 0.42 + wobble + pointer.current.x * 0.22;
    group.rotation.x = pointer.current.y * -0.1;
  });

  return (
    <group ref={ref}>
      {(Object.keys(MODELS) as ModelId[]).map((id) => {
        const Model = MODELS[id];
        return (
          <Cluster key={id} id={id} focus={focus}>
            <Model />
          </Cluster>
        );
      })}
      <Chips />
    </group>
  );
}

function FrameCamera() {
  const { camera, size } = useThree();
  useEffect(() => {
    const cam = camera as THREE.PerspectiveCamera;
    const narrow = size.width < 760;
    cam.fov = narrow ? 48 : 38;
    cam.position.set(narrow ? 0.15 : -0.35, narrow ? 1.45 : 1.05, narrow ? 7.4 : 6.9);
    cam.lookAt(narrow ? 0.85 : 0.25, narrow ? 0.32 : 0.35, 0);
    cam.updateProjectionMatrix();
  }, [camera, size.width, size.height]);
  return null;
}

function Scene({ focus }: { focus: Focus }) {
  const narrow = useThree((state) => state.size.width < 760);
  return (
    <>
      <FrameCamera />
      <hemisphereLight color="#fff6e4" groundColor="#3a1466" intensity={0.9} />
      <ambientLight intensity={0.28} />
      <directionalLight position={[5, 7, 4]} intensity={2.5} color="#fffaf2" />
      <directionalLight position={[-6, 3, 2]} intensity={1.7} color="#3ecbff" />
      <directionalLight position={[2, 1.5, -4]} intensity={1.15} color="#ff4f9a" />
      <pointLight position={[1.4, 1.6, 2.4]} intensity={2.2} color="#ffd23f" distance={14} />
      <group scale={narrow ? 0.7 : 1} position={[narrow ? 0.95 : 0, narrow ? 0.12 : 0, 0]}>
        <Stage />
        <Rig focus={focus} />
      </group>
    </>
  );
}

function supportsWebGL() {
  try {
    const canvas = document.createElement("canvas");
    return Boolean(
      window.WebGLRenderingContext &&
        (canvas.getContext("webgl2") || canvas.getContext("webgl")),
    );
  } catch {
    return false;
  }
}

export function StoreScene({ focus }: { focus: Focus }) {
  const [enabled, setEnabled] = useState(true);

  useEffect(() => {
    setEnabled(supportsWebGL());
  }, []);

  if (!enabled) {
    return (
      <div className="stage-canvas css-stage" aria-hidden="true">
        <div className="float-cube c1" />
        <div className="float-cube c2" />
        <div className="float-cube c3" />
      </div>
    );
  }

  return (
    <div className="stage-canvas" aria-hidden="true">
      <Canvas
        dpr={[1, 1.75]}
        gl={{ antialias: true, alpha: true, toneMapping: THREE.NoToneMapping }}
        camera={{ position: [-0.35, 1.05, 6.9], fov: 38, near: 0.1, far: 40 }}
        onCreated={({ gl }) => {
          gl.setClearColor(0x000000, 0);
        }}
      >
        <Scene focus={focus} />
      </Canvas>
    </div>
  );
}
