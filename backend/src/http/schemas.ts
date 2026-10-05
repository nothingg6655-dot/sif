import { z } from "zod";
import { toDecimal } from "../lib/money.js";

const decimalValue = z.union([z.string(), z.number()]).refine(value => toDecimal(value) !== null, "Expected a finite decimal value");
const positiveDecimal = decimalValue.refine(value => toDecimal(value)?.gt(0) === true, "Value must be greater than zero");

export const paginationQuery = z.object({
  q: z.string().optional(),
  category: z.string().optional(),
  amcId: z.coerce.number().int().positive().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

export const idParam = z.object({
  schemeId: z.coerce.number().int().positive(),
});

export const planIdParam = z.object({
  planId: z.coerce.number().int().positive(),
});

export const benchmarkIdParam = z.object({
  benchmarkId: z.coerce.number().int().positive(),
});

export const ingestionIdParam = z.object({
  id: z.coerce.number().int().positive(),
});

export const dateRangeQuery = z.object({
  from: z.string().date().optional(),
  to: z.string().date().optional(),
}).refine(({ from, to }) => !from || !to || from <= to, "from must be on or before to");

export const dateQuery = z.object({
  date: z.string().date().optional(),
});

export const periodQuery = z.object({
  period: z.enum(["1M", "3M", "6M", "1Y", "SINCE_INCEPTION"]).optional(),
});

export const rollingPeriodQuery = z.object({
  period: z.enum(["1M", "3M", "6M"]).optional(),
});

export const compareQuery = z.object({
  ids: z
    .string()
    .min(1)
    .transform((value) =>
      value
        .split(",")
        .map((part) => /^\d+$/.test(part.trim()) ? Number(part.trim()) : NaN),
    )
    .refine((ids) => ids.length > 0 && ids.every(id => Number.isSafeInteger(id) && id > 0), "Every scheme id must be a positive integer")
    .refine((ids) => ids.length <= 5, "Compare at most 5 funds at a time."),
});

export const compareReturnsQuery = compareQuery.extend({
  period: z.enum(["1M", "3M", "6M", "1Y", "SINCE_INCEPTION"]).default("3M"),
});

export const searchQuery = z.object({
  q: z.string().min(1),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(50).default(20),
});

export const topHoldingsQuery = z.object({
  limit: z.coerce.number().int().positive().max(50).default(10),
});

export const navImportBody = z.object({
  planId: z.number().int().positive(),
  source: z.string().min(1).max(255),
  rows: z
    .array(
      z.object({
        navDate: z.string().date(),
        nav: positiveDecimal,
        repurchasePrice: decimalValue.optional(),
        salePrice: decimalValue.optional(),
      }),
    )
    .min(1)
    .max(5000),
});

export const aumImportBody = z.object({
  schemeId: z.number().int().positive(),
  source: z.string().min(1).max(255),
  rows: z
    .array(
      z.object({
        reportDate: z.string().date(),
        periodType: z.string().default("MONTHLY"),
        closingAum: decimalValue.nullable().optional(),
        averageAum: decimalValue.nullable().optional(),
        unit: z.string().default("CRORE"),
      }),
    )
    .min(1)
    .max(1000),
});

export const portfolioImportBody = z.object({
  schemeId: z.number().int().positive(),
  reportDate: z.string().date(),
  sourceFile: z.string().min(1).max(500),
  positions: z
    .array(
      z.object({
        instrumentName: z.string().min(1).max(500),
        instrumentType: z.string().max(100).optional(),
        assetClass: z.string().max(100).optional(),
        sector: z.string().max(255).optional(),
        positionSide: z.enum(["LONG", "SHORT", "HEDGED", "OFFSET", "NA"]).default("NA"),
        quantity: decimalValue.optional(),
        marketValue: decimalValue.optional(),
        navPercentage: decimalValue.optional(),
        exposureValue: decimalValue.optional(),
        exposurePercentage: decimalValue.optional(),
        derivativeUnderlying: z.string().max(255).optional(),
        derivativeType: z.string().max(100).optional(),
        expiryDate: z.string().date().optional(),
        contractIdentifier: z.string().max(255).optional(),
        isin: z.string().max(30).optional(),
      }),
    )
    .max(5000),
});

export const benchmarkImportBody = z.object({
  benchmarkId: z.number().int().positive(),
  source: z.string().min(1).max(255),
  rows: z
    .array(
      z.object({
        valueDate: z.string().date(),
        indexValue: positiveDecimal,
      }),
    )
    .min(1)
    .max(5000),
});

export const riskFreeImportBody = z.object({
  instrument: z.string().min(1).max(100),
  source: z.string().min(1).max(255),
  rows: z
    .array(
      z.object({
        rateDate: z.string().date(),
        annualRate: decimalValue,
      }),
    )
    .min(1)
    .max(5000),
});
