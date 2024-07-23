ALTER TABLE [NycRollingSales].[dbo].[nyc-rolling-sales]
ADD 
    sale_price_zscore_neighborhood FLOAT,
    square_ft_per_unit FLOAT,
    price_per_unit FLOAT;
GO

WITH NeighborhoodStats AS (
    SELECT 
        NEIGHBORHOOD, 
        [BUILDING_CLASS_CATEGORY],
        AVG(TRY_CONVERT(FLOAT, NULLIF([SALE_PRICE], '-'))) AS avg_sale_price_neighborhood,
        STDEV(TRY_CONVERT(FLOAT, NULLIF([SALE_PRICE], '-'))) AS stddev_sale_price_neighborhood
    FROM 
        [NycRollingSales].[dbo].[nyc-rolling-sales]
    WHERE 
        TRY_CONVERT(FLOAT, NULLIF([SALE_PRICE], '-')) IS NOT NULL
    GROUP BY 
        NEIGHBORHOOD, 
        [BUILDING_CLASS_CATEGORY]
)
UPDATE [NycRollingSales].[dbo].[nyc-rolling-sales]
SET 
    sale_price_zscore_neighborhood = (TRY_CONVERT(FLOAT, NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[SALE_PRICE], '-')) - NeighborhoodStats.avg_sale_price_neighborhood) / NULLIF(NeighborhoodStats.stddev_sale_price_neighborhood, 0),
    square_ft_per_unit = TRY_CONVERT(FLOAT, NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[GROSS_SQUARE_FEET], '-')) / NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[TOTAL_UNITS], 0),
    price_per_unit = TRY_CONVERT(FLOAT, NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[SALE_PRICE], '-')) / NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[TOTAL_UNITS], 0)
FROM 
    [NycRollingSales].[dbo].[nyc-rolling-sales]
    INNER JOIN NeighborhoodStats
    ON [NycRollingSales].[dbo].[nyc-rolling-sales].NEIGHBORHOOD = NeighborhoodStats.NEIGHBORHOOD 
    AND [NycRollingSales].[dbo].[nyc-rolling-sales].[BUILDING_CLASS_CATEGORY] = NeighborhoodStats.[BUILDING_CLASS_CATEGORY]
WHERE 
    [NycRollingSales].[dbo].[nyc-rolling-sales].[TOTAL_UNITS] > 0
    AND TRY_CONVERT(FLOAT, NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[SALE_PRICE], '-')) IS NOT NULL
    AND TRY_CONVERT(FLOAT, NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[GROSS_SQUARE_FEET], '-')) IS NOT NULL
    AND TRY_CONVERT(FLOAT, NULLIF([NycRollingSales].[dbo].[nyc-rolling-sales].[LAND_SQUARE_FEET], '-')) IS NOT NULL;
GO
