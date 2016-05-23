diff --git a/include/asio/ssl/detail/impl/engine.ipp b/include/asio/ssl/detail/impl/engine.ipp
index 5504411..4393e3d 100644
--- a/include/asio/ssl/detail/impl/engine.ipp
+++ b/include/asio/ssl/detail/impl/engine.ipp
@@ -198,9 +198,15 @@ const asio::error_code& engine::map_error_code(
   // If there's data yet to be read, it's an error.
   if (BIO_wpending(ext_bio_))
   {
+#if defined(OPENSSL_IS_BORINGSSL)
+	ec = asio::error_code(
+		ERR_PACK(ERR_LIB_SSL, SSL_R_UNEXPECTED_RECORD),
+		asio::error::get_ssl_category());
+#else // defined(OPENSSL_IS_BORINGSSL
     ec = asio::error_code(
         ERR_PACK(ERR_LIB_SSL, 0, SSL_R_SHORT_READ),
         asio::error::get_ssl_category());
+#endif // defined(OPENSSL_IS_BORINGSSL)
     return ec;
   }
 
@@ -212,9 +218,15 @@ const asio::error_code& engine::map_error_code(
   // Otherwise, the peer should have negotiated a proper shutdown.
   if ((::SSL_get_shutdown(ssl_) & SSL_RECEIVED_SHUTDOWN) == 0)
   {
+#if defined(OPENSSL_IS_BORINGSSL)
+	  ec = asio::error_code(
+		ERR_PACK(ERR_LIB_SSL, SSL_R_UNEXPECTED_RECORD),
+		asio::error::get_ssl_category());
+#else // defined(OPENSSL_IS_BORINGSSL
     ec = asio::error_code(
         ERR_PACK(ERR_LIB_SSL, 0, SSL_R_SHORT_READ),
         asio::error::get_ssl_category());
+#endif
   }
 
   return ec;
diff --git a/include/asio/ssl/detail/impl/openssl_init.ipp b/include/asio/ssl/detail/impl/openssl_init.ipp
index 2c40d40..02349d1 100644
--- a/include/asio/ssl/detail/impl/openssl_init.ipp
+++ b/include/asio/ssl/detail/impl/openssl_init.ipp
@@ -36,7 +36,7 @@ public:
   do_init()
   {
     ::SSL_library_init();
-    ::SSL_load_error_strings();        
+	::SSL_load_error_strings();
     ::OpenSSL_add_all_algorithms();
 
     mutexes_.resize(::CRYPTO_num_locks());
@@ -66,7 +66,9 @@ public:
     ::ERR_remove_state(0);
     ::EVP_cleanup();
     ::CRYPTO_cleanup_all_ex_data();
+#if !defined(OPENSSL_IS_BORINGSSL)
     ::CONF_modules_unload(1);
+#endif // defined(OPENSSL_IS_BORINGSSL)
 #if !defined(OPENSSL_NO_ENGINE)
     ::ENGINE_cleanup();
 #endif // !defined(OPENSSL_NO_ENGINE)
diff --git a/include/asio/ssl/impl/context.ipp b/include/asio/ssl/impl/context.ipp
index ed55ef1..7bdd7d2 100644
--- a/include/asio/ssl/impl/context.ipp
+++ b/include/asio/ssl/impl/context.ipp
@@ -538,13 +538,17 @@ asio::error_code context::use_certificate_chain(
           asio::error::get_ssl_category());
       return ec;
     }
-
+	  
+#if (OPENSSL_VERSION_NUMBER >= 0x10002000L)
+	::SSL_CTX_clear_chain_certs(handle_);
+#else
     if (handle_->extra_certs)
     {
       ::sk_X509_pop_free(handle_->extra_certs, X509_free);
       handle_->extra_certs = 0;
     }
-
+#endif // (OPENSSL_VERSION_NUMBER >= 0x10002000L)
+	  
     while (X509* cacert = ::PEM_read_bio_X509(bio.p, 0,
           handle_->default_passwd_callback,
           handle_->default_passwd_callback_userdata))
