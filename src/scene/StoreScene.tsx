import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { RoundedBox } from "@react-three/drei";
import * as THREE from "three";
import { modelFor, type Focus, type ModelId } from "../content";

const HOMES: Record<ModelId, [number, number, number]> = {
  sanitary: [1.05, 0.28, 0.4],
  pipes: [2.85, 0.42, -0.05],
  hardware: [2.05, -0.12, 0.9],
  mill: [1.85, 1.28, -0.7],
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

function Gear({ color, spin = 0.4 }: { color: string; spin?: number }) {
  const ref = useRef<THREE.Group>(null);
  useFrame((state) => {
    if (ref.current) ref.current.rotation.z = state.clock.elapsedTime * spin;
  });
  return (
    <group ref={ref}>
      <mesh>
        <torusGeometry args={[0.62, 0.13, 18, 48]} />
        <Paint color={color} metalness={0.58} roughness={0.26} />
      </mesh>
      <mesh rotation={[Math.PI / 2, 0, 0]}>
        <cylinderGeometry args={[0.2, 0.2, 0.18, 24]} />
        <Paint color="#fff6ea" metalness={0.35} roughness={0.3} />
      </mesh>
      {Array.from({ length: 12 }, (_, index) => {
        const angle = (index / 12) * Math.PI * 2;
        return (
          <mesh
            key={index}
            position={[Math.cos(angle) * 0.78, Math.sin(angle) * 0.78, 0]}
            rotation={[0, 0, angle]}
          >
            <boxGeometry args={[0.16, 0.22, 0.14]} />
            <Paint color={color} metalness={0.58} roughness={0.26} />
          </mesh>
        );
      })}
    </group>
  );
}

function Sanitary() {
  return (
    <group>
      <RoundedBox args={[1.45, 0.16, 0.9]} radius={0.05} position={[0, -0.22, 0]}>
        <Paint color="#f7fdff" roughness={0.16} metalness={0.05} />
      </RoundedBox>
      <RoundedBox args={[0.95, 0.34, 0.6]} radius={0.12} position={[0, 0.04, 0]}>
        <Paint color="#67e4ff" roughness={0.14} metalness={0.08} />
      </RoundedBox>
      <mesh position={[0, 0.16, 0.02]} scale={[1, 0.42, 0.7]}>
        <sphereGeometry args={[0.3, 28, 18]} />
        <Paint color="#e7fbff" roughness={0.12} metalness={0.04} />
      </mesh>
      <group position={[0.32, 0.32, 0.2]}>
        <mesh>
          <cylinderGeometry args={[0.032, 0.04, 0.3, 16]} />
          <Paint color="#d5deea" metalness={0.82} roughness={0.18} />
        </mesh>
        <mesh position={[0.13, 0.13, 0]} rotation={[0, 0, Math.PI / 2]}>
          <cylinderGeometry args={[0.028, 0.028, 0.24, 16]} />
          <Paint color="#d5deea" metalness={0.82} roughness={0.18} />
        </mesh>
        <mesh position={[0.24, 0.05, 0]}>
          <cylinderGeometry args={[0.024, 0.018, 0.14, 12]} />
          <Paint color="#d5deea" metalness={0.82} roughness={0.18} />
        </mesh>
        <mesh position={[-0.12, 0.14, 0]}>
          <sphereGeometry args={[0.048, 18, 18]} />
          <Paint color="#ffd23f" metalness={0.7} roughness={0.2} />
        </mesh>
      </group>
      <mesh position={[-0.62, 0.0, 0.34]}>
        <cylinderGeometry args={[0.08, 0.09, 0.22, 18]} />
        <Paint color="#ff4f9a" roughness={0.32} metalness={0.12} />
      </mesh>
    </group>
  );
}

function Pipes() {
  const colors = ["#ff5a1f", "#2f6bff", "#8dff63", "#fff6ea", "#ffd23f"];
  return (
    <group>
      {colors.map((color, index) => (
        <mesh
          key={color}
          position={[0, (index - 2) * 0.2, 0]}
          rotation={[0, 0, Math.PI / 2]}
        >
          <cylinderGeometry args={[0.078, 0.078, 1.5, 20]} />
          <Paint color={color} metalness={0.22} roughness={0.22} />
        </mesh>
      ))}
      <mesh position={[0.1, 0.2, 0.48]} rotation={[0.7, 0.2, 0.5]}>
        <torusGeometry args={[0.4, 0.075, 16, 40]} />
        <Paint color="#ff4f9a" metalness={0.3} />
      </mesh>
      <mesh position={[-0.15, -0.2, 0.55]} rotation={[1.1, 0.4, 0.2]}>
        <torusGeometry args={[0.3, 0.065, 14, 28, Math.PI]} />
        <Paint color="#49d2ff" metalness={0.25} />
      </mesh>
    </group>
  );
}

const BOLTS: Array<[number, number, number]> = [
  [-0.62, 0.48, 0.32],
  [-0.32, 0.62, 0.12],
  [0.42, 0.58, 0.42],
];

function Hardware() {
  return (
    <group>
      <RoundedBox args={[1.05, 0.28, 0.74]} radius={0.05} position={[0, -0.18, 0]}>
        <Paint color="#e1062a" metalness={0.38} roughness={0.28} />
      </RoundedBox>
      <RoundedBox args={[0.82, 0.24, 0.58]} radius={0.05} position={[0.06, 0.1, 0.02]}>
        <Paint color="#ffd23f" metalness={0.42} roughness={0.26} />
      </RoundedBox>
      <RoundedBox args={[0.58, 0.2, 0.42]} radius={0.04} position={[-0.04, 0.32, 0]}>
        <Paint color="#d5dee8" metalness={0.72} roughness={0.2} />
      </RoundedBox>
      <group position={[0.78, 0.12, 0.38]}>
        <RoundedBox args={[0.3, 0.26, 0.16]} radius={0.04}>
          <Paint color="#24142b" metalness={0.5} roughness={0.35} />
        </RoundedBox>
        <mesh position={[0, 0.14, 0]} rotation={[Math.PI, 0, 0]}>
          <torusGeometry args={[0.1, 0.028, 12, 18, Math.PI]} />
          <Paint color="#e6b84d" metalness={0.78} roughness={0.22} />
        </mesh>
      </group>
      {BOLTS.map((position, index) => (
        <group key={position.join()} position={position} rotation={[0.3, 0.2, index * 0.4]}>
          <mesh>
            <cylinderGeometry args={[0.038, 0.038, 0.24, 12]} />
            <Paint color="#e6b84d" metalness={0.78} roughness={0.24} />
          </mesh>
          <mesh position={[0, 0.14, 0]}>
            <sphereGeometry args={[0.058, 16, 16]} />
            <Paint color="#e6b84d" metalness={0.78} roughness={0.24} />
          </mesh>
        </group>
      ))}
    </group>
  );
}

function Mill() {
  return (
    <group>
      <group position={[-0.2, 0.05, 0]} rotation={[0.5, 0.45, 0.15]}>
        <Gear color="#ffb000" spin={0.45} />
      </group>
      <group position={[0.95, -0.4, 0.2]} rotation={[0.55, -0.2, 0.5]} scale={0.62}>
        <Gear color="#ff4f9a" spin={-0.75} />
      </group>
      <mesh position={[0.25, -0.62, 0.4]} rotation={[0, 0, Math.PI / 2]}>
        <cylinderGeometry args={[0.16, 0.16, 1.15, 24]} />
        <Paint color="#49d2ff" metalness={0.48} roughness={0.22} />
      </mesh>
      <mesh position={[-0.85, 0.5, 0.15]} rotation={[0.2, 0.3, 0.4]}>
        <coneGeometry args={[0.34, 0.5, 22]} />
        <Paint color="#ff5a1f" metalness={0.32} />
      </mesh>
    </group>
  );
}

const MODELS: Record<ModelId, () => ReactNode> = {
  sanitary: Sanitary,
  pipes: Pipes,
  hardware: Hardware,
  mill: Mill,
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
