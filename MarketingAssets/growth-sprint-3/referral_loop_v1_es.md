# Sprint 3 Referral Loop v1

Última actualización: 2026-04-09

## Decisión

Sprint 3 deja listo el referral loop como sistema de lanzamiento, pero no lo mezcla con el invite de Family Spaces ni promete rewards automáticos antes de tener backend.

El loop v1 se enfoca en tres acciones:

- compartir un logro o primer avance desde la app;
- llevar a un amigo a TestFlight/App Store con UTM y deep link;
- medir activación real antes de decidir rewards.

## User Journey

1. Usuario completa una señal positiva: primer gasto, primer escaneo, presupuesto creado o logro desbloqueado.
2. La app muestra una invitación suave: `¿Te sirvió? Compártelo con alguien que también está tratando de ordenar su mes.`
3. El share abre la hoja nativa con un link medible.
4. La persona invitada instala o entra por TestFlight/App Store.
5. Se mide activación: onboarding completado + primer gasto, escaneo o presupuesto.
6. Cuando exista backend referral ledger, se puede otorgar reward después de activación, no por install.

## Copy de Share

### Logro compartido

```text
Hoy avancé un poco con mis gastos en SpendSage. Si también quieres ordenar tu mes sin complicarte, pruébala aquí:
{link}
```

### Invitación directa

```text
Estoy probando SpendSage para registrar gastos, escanear recibos y entender el mes más fácil. Creo que te puede servir:
{link}
```

### Beta/TestFlight

```text
Estoy probando la beta de SpendSage. Es una app para registrar gastos, escanear recibos y ver tu progreso sin sentirlo pesado:
{link}
```

## Deep Link y UTM

Base para links sociales:

```text
https://spendsage.ai/?utm_source={platform}&utm_medium=referral&utm_campaign=spendsage_sprint3_referral&utm_content={share_surface}&ref={code}
```

Valores recomendados para `utm_content`:

- `achievement_share`
- `first_expense_share`
- `scan_success_share`
- `budget_created_share`
- `settings_invite`

## Eventos

| Evento | Cuándo se dispara | Propiedades |
| --- | --- | --- |
| `referral_share_started` | Usuario toca compartir | `surface`, `share_type`, `space_scope` |
| `referral_share_completed` | Share sheet finaliza si el sistema lo reporta | `surface`, `share_type` |
| `referral_link_opened` | Landing/app recibe link con `ref` | `utm_source`, `utm_content`, `ref_code_present` |
| `referral_activation_qualified` | Invitado completa activación | `activation_type`, `days_to_activation` |
| `referral_reward_pending` | Backend acepta reward pendiente | `reward_type`, `activation_gate` |
| `referral_reward_granted` | Reward se otorga | `reward_type`, `granted_after_hours` |

## Reward Policy

No recompensar por rating, review o permiso de notificaciones.

Reward recomendado para v1:

- invitado: 14 a 30 días de Pro después de activación;
- invitador: 14 a 30 días de Pro después de activación del invitado;
- Family: mantener separado del invite de hogar para evitar confusión entre colaboración y viral loop.

## Requisitos de Backend Antes de Activar Rewards

- tabla o entidad `ReferralCode`;
- relación `inviterUserId` y `referredUserId`;
- estado `created`, `signed_up`, `activated`, `rewarded`, `rejected`;
- bloqueo de self-referral;
- dedupe por usuario autenticado;
- reward pendiente hasta que exista activación;
- panel manual para revisar abusos antes de escalar.

## CTA en Producto

Superficies aprobadas para diseño futuro:

- celebration popup: `Compartir mi logro`;
- settings: `Invita a un amigo`;
- premium: `Comparte SpendSage`;
- post-onboarding: `Enviar a alguien que lo necesita`.

Evitar popups agresivos en cold start o antes de que el usuario haya visto valor real.
