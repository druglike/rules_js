"""Unit tests for npm auth
See https://docs.bazel.build/versions/main/skylark/testing.html#for-testing-starlark-utilities
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//npm/private:npm_translate_lock.bzl", "get_npm_auth")

def _no_npmrc_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        ({}, {}),
        get_npm_auth(
            {},
            "",
            {},
        ),
    )

    return unittest.end(env)

def _plain_text_token_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {
                "registry1": "TOKEN1",
            },
            {},
        ),
        get_npm_auth(
            {
                "//registry1/:_authtoken": "TOKEN1",
            },
            "",
            {
                "TOKEN1": "1234",
            },
        ),
    )

    asserts.equals(
        env,
        (
            {
                "registry1": "TOKEN1",
                "registry2": "TOKEN2",
            },
            {},
        ),
        get_npm_auth(
            {
                "//registry1/:_authtoken": "TOKEN1",
                "//registry2/:_authtoken": "TOKEN2",
            },
            "",
            {
                "TOKEN1": "1234",
                "TOKEN2": "5678",
            },
        ),
    )

    return unittest.end(env)

def _env_var_token_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {
                "registry1": "TOKEN1",
            },
            {},
        ),
        get_npm_auth(
            {
                "//registry1/:_authtoken": "$TOKEN1",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {
                "registry1": "1234",
            },
            {},
        ),
        get_npm_auth(
            {
                "//registry1/:_authtoken": "$TOKEN1",
            },
            "",
            {
                "TOKEN1": "1234",
            },
        ),
    )

    asserts.equals(
        env,
        (
            {
                "registry1": "1234",
            },
            {},
        ),
        get_npm_auth(
            {
                "//registry1/:_authtoken": "${%s}" % "TOKEN1",
            },
            "",
            {
                "TOKEN1": "1234",
            },
        ),
    )

    asserts.equals(
        env,
        (
            {
                "registry1": "1234",
                "registry2": "5678",
            },
            {},
        ),
        get_npm_auth(
            {
                "//registry1/:_authtoken": "${%s}" % "TOKEN1",
                "//registry2/:_authtoken": "${%s}" % "TOKEN2",
            },
            "",
            {
                "TOKEN1": "1234",
                "TOKEN2": "5678",
            },
        ),
    )
    return unittest.end(env)

def _mixed_token_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {
                "registry1": "TOKEN1",
                "registry2": "5678",
            },
            {},
        ),
        get_npm_auth(
            {
                "//registry1/:_authtoken": "TOKEN1",
                "//registry2/:_authtoken": "${%s}" % "TOKEN2",
            },
            "",
            {
                "TOKEN2": "5678",
            },
        ),
    )

    return unittest.end(env)

def _pkg_scope_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(
        env,
        (
            {},
            {
                "@scope1": "https://registry1",
            },
        ),
        get_npm_auth(
            {
                "@scope1:registry": "https://registry1",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "@scope1": "https://registry1",
                "@scope2": "https://registry2",
            },
        ),
        get_npm_auth(
            {
                "@scope1:registry": "https://registry1",
                "@scope2:registry": "https://registry2",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "@scope1": "https://registry/scope1",
                "@scope2": "https://registry/scope2",
            },
        ),
        get_npm_auth(
            {
                "@scope1:registry": "https://registry/scope1",
                "@scope2:registry": "https://registry/scope2",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "@scope1": "http://registry/scope1",
                "@scope2": "https://registry/scope2",
                "@scope3": "//registry/scope3",
                "@scope4": "https://registry4.com",
            },
        ),
        get_npm_auth(
            {
                "@scope1:registry": "http://registry/scope1",
                "@scope2:registry": "https://registry/scope2",
                "@scope3:registry": "//registry/scope3",
                "@scope4:registry": "registry4.com",
            },
            "",
            {},
        ),
    )

    asserts.equals(
        env,
        (
            {},
            {
                "@scope1": "https://registry/scope1",
                "@scope2": "https://registry/scope2",
            },
        ),
        get_npm_auth(
            {
                "@scope1:registry": "https://registry/scope1",
                "@scope2:registry": "https://registry/scope2",
            },
            "",
            {},
        ),
    )

    return unittest.end(env)

no_npmrc_test = unittest.make(_no_npmrc_test_impl)
plain_text_token_test = unittest.make(_plain_text_token_test_impl)
env_var_token_test = unittest.make(_env_var_token_test_impl)
mixed_token_test = unittest.make(_mixed_token_test_impl)
pkg_scope_test = unittest.make(_pkg_scope_test_impl)

def npm_auth_test_suite():
    unittest.suite(
        "npm_auth_tests",
        partial.make(no_npmrc_test, timeout = "short"),
        partial.make(plain_text_token_test, timeout = "short"),
        partial.make(env_var_token_test, timeout = "short"),
        partial.make(mixed_token_test, timeout = "short"),
        partial.make(pkg_scope_test, timeout = "short"),
    )
