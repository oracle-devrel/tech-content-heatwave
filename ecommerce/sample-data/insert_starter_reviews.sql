use demo;

delete from reviews;
ALTER TABLE reviews AUTO_INCREMENT = 1;
insert into reviews(product_id, customer_id, language_code, rating, review_text) VALUES 
('1', '1', 'en', 2, 'Overall, while the Shirt has some strengths, it did not fully live up to my expectations. The lack of machine washability and the absence of cotton are major drawbacks for someone like me who prefers durable and comfortable fabrics. Additionally, while the Shirt is perfect for casual outings, it may not be the best choice for more formal occasions. However, if someone else shares my personality traits and values durability and comfort in their clothing, I would still recommend this Shirt as a decent option for everyday wear.'),
('1', '2', 'en', 5, "I recently purchased a shirt from the company and I must say that it exceeded my expectations. The shirt is made from high-quality cotton and is incredibly soft to the touch. The material is also very breathable, making it perfect for casual outings.

One of the strengths of this shirt is its versatility. It can be dressed up or down depending on the occasion, making it a great investment piece for any wardrobe. Additionally, the shirt is available in multiple colors and sizes, so it's easy to find one that fits your personal style and preferences.

However, one weakness of the shirt is that it can only be hand washed. This is a bit of a downside for those who prefer to machine wash their clothes. However, the hand wash instructions are easy to follow and the shirt dries quickly, so it's not a major inconvenience.

Overall, I would highly recommend this shirt to others who share my personality traits. It's a great investment piece that is both comfortable and versatile. The high-quality cotton and soft material make it a great choice for everyday wear, while the versatility of the shirt allows it to be dressed up or down for any occasion.");
