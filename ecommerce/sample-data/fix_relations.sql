use demo;

delete from reviews_customer_links;
insert into reviews_customer_links (review_id, customer_id, review_order) select id, customer_id, 1 from reviews;

delete from reviews_product_links;
insert into reviews_product_links (review_id, product_id, review_order) select id, product_id, 1 from reviews;

delete from productdescriptions_product_links;
insert into productdescriptions_product_links (productdescription_id, product_id, productdescription_order) select id, product_id, 1 from productdescriptions;