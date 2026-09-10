import { Decimal } from "decimal.js";

Decimal.set({ precision: 40, rounding: Decimal.ROUND_HALF_UP });

export function toDecimal(value: string | number | Decimal | null | undefined): Decimal | null {
  if (value === null || value === undefined || value === "") {
    return null;
  }
  try {
    const parsed = new Decimal(value);
    if (!parsed.isFinite()) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

export function toJsonNumber(value: string | number | Decimal | null | undefined): number | null {
  const parsed = toDecimal(value);
  if (parsed === null) {
    return null;
  }
  return parsed.toNumber();
}

export function toIsoDate(value: Date | string | null | undefined): string | null {
  if (value === null || value === undefined) {
    return null;
  }
  if (typeof value === "string") {
    return value.slice(0, 10);
  }
  return value.toISOString().slice(0, 10);
}

export function requireIsoDate(value: Date | string | null | undefined): string {
  const iso = toIsoDate(value);
  if (!iso) {
    throw new Error("Expected a date value");
  }
  return iso;
}
