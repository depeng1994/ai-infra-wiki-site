#!/usr/bin/env python3
"""Browser regression checks for the desktop mobile-style drawer."""

from __future__ import annotations

import argparse
import asyncio
from pathlib import Path
from urllib.parse import urlparse

from playwright.async_api import Page, async_playwright


async def open_drawer(page: Page) -> None:
    await page.locator('label.md-header__button[for="__drawer"]').click()
    await page.wait_for_timeout(300)


async def layout_geometry(page: Page) -> dict[str, float]:
    return await page.evaluate(
        """() => {
          const rect = selector => {
            const box = document.querySelector(selector).getBoundingClientRect()
            return {x: box.x, width: box.width}
          }
          return {
            header: rect('.md-header'),
            main: rect('.md-main'),
            content: rect('.md-content'),
            footer: rect('.md-footer')
          }
        }"""
    )


async def verify_desktop(page: Page, url: str, screenshot: Path | None) -> None:
    await page.goto(url, wait_until="networkidle")
    await page.evaluate("localStorage.removeItem('llm-infra-wiki:desktop-drawer-pinned')")
    await page.reload(wait_until="networkidle")

    layout = await page.evaluate(
        """() => {
          const content = document.querySelector('.md-content').getBoundingClientRect()
          const secondary = document.querySelector('.md-sidebar--secondary')
          return {
            contentWidth: content.width,
            secondaryDisplay: getComputedStyle(secondary).display,
            drawerButtonDisplay: getComputedStyle(
              document.querySelector('label.md-header__button[for="__drawer"]')
            ).display
          }
        }"""
    )
    assert layout["secondaryDisplay"] == "none", layout
    assert layout["drawerButtonDisplay"] != "none", layout
    assert layout["contentWidth"] >= 1439, layout

    await open_drawer(page)
    drawer = await page.locator(".md-sidebar--primary").bounding_box()
    assert drawer == {"x": 0, "y": 0, "width": 242, "height": 900}, drawer
    overlay = await page.evaluate(
        """() => ({
          width: getComputedStyle(document.querySelector('.md-overlay')).width,
          height: getComputedStyle(document.querySelector('.md-overlay')).height,
          opacity: getComputedStyle(document.querySelector('.md-overlay')).opacity,
          pointerEvents: getComputedStyle(document.querySelector('.md-overlay')).pointerEvents
        })"""
    )
    assert overlay == {
        "width": "0px",
        "height": "0px",
        "opacity": "0",
        "pointerEvents": "none",
    }, overlay

    shifted = await layout_geometry(page)
    for name, box in shifted.items():
        assert box == {"x": 242, "width": 1198}, (name, box, shifted)

    next_href = await page.locator(".md-footer__link--next").get_attribute("href")
    assert next_href
    next_path = urlparse(next_href).path
    await page.evaluate("window.__drawerBeforeInstantNavigation = document.querySelector('.md-sidebar--primary')")
    await page.locator(".md-footer__link--next").click()
    await page.wait_for_timeout(700)
    instant = await page.evaluate(
        """() => ({
          url: location.pathname,
          drawerPreserved: window.__drawerBeforeInstantNavigation === document.querySelector('.md-sidebar--primary'),
          checked: document.querySelector('#__drawer').checked,
          main: (() => { const b = document.querySelector('.md-main').getBoundingClientRect(); return {x:b.x,width:b.width} })(),
          heading: document.querySelector('.md-content h1')?.textContent.trim(),
          activePaths: Array.from(document.querySelectorAll('.md-sidebar--primary a.md-nav__link--active'))
            .map(link => new URL(link.href).pathname)
        })"""
    )
    assert instant["url"] == next_path, instant
    assert instant["drawerPreserved"] is True, instant
    assert instant["checked"] is True, instant
    assert instant["main"] == {"x": 242, "width": 1198}, instant
    assert instant["heading"], instant
    assert instant["activePaths"] == [next_path], instant

    await page.evaluate("window.history.back()")
    await page.wait_for_timeout(700)
    back = await page.evaluate(
        """() => ({
          url: location.pathname,
          drawerPreserved: window.__drawerBeforeInstantNavigation === document.querySelector('.md-sidebar--primary'),
          checked: document.querySelector('#__drawer').checked,
          main: (() => { const b = document.querySelector('.md-main').getBoundingClientRect(); return {x:b.x,width:b.width} })()
        })"""
    )
    assert back == {
        "url": "/",
        "drawerPreserved": True,
        "checked": True,
        "main": {"x": 242, "width": 1198},
    }, back

    await page.evaluate(
        "document.querySelector('a.md-nav__link[href$=\"/01-compute-memory/\"]').click()"
    )
    await page.wait_for_timeout(700)
    nested = await page.evaluate(
        """() => {
          const active = document.querySelector('a.md-nav__link[href$="/01-compute-memory/"]')
          const branch = active.closest('.md-nav__item--nested')
          const childNav = branch.querySelector(':scope > nav.md-nav')
          return {
            path: location.pathname,
            checked: branch.querySelector(':scope > input.md-nav__toggle').checked,
            expanded: childNav.getAttribute('aria-expanded'),
            opacity: getComputedStyle(childNav).opacity,
            activePath: new URL(document.querySelector('.md-sidebar--primary a.md-nav__link--active').href).pathname
          }
        }"""
    )
    assert nested == {
        "path": "/01-compute-memory/",
        "checked": True,
        "expanded": "true",
        "opacity": "1",
        "activePath": "/01-compute-memory/",
    }, nested

    pin = page.locator("button.md-drawer-pin")
    assert await pin.count() == 1
    assert await pin.get_attribute("aria-pressed") == "false"
    await pin.click()
    await page.wait_for_timeout(100)
    pinned = await page.evaluate(
        """() => ({
          checked: document.querySelector('#__drawer').checked,
          stored: localStorage.getItem('llm-infra-wiki:desktop-drawer-pinned'),
          pressed: document.querySelector('button.md-drawer-pin').getAttribute('aria-pressed')
        })"""
    )
    assert pinned == {"checked": True, "stored": "true", "pressed": "true"}, pinned

    await page.evaluate(
        "document.querySelector('a.md-nav__link[href$=\"/00-roadmap/\"]').click()"
    )
    await page.wait_for_timeout(500)
    assert page.url.endswith("/00-roadmap/"), page.url
    assert await page.locator("button.md-drawer-pin").count() == 1
    assert await page.locator("#__drawer").is_checked()
    await page.reload(wait_until="networkidle")
    assert await page.locator("#__drawer").is_checked()
    assert await page.locator("button.md-drawer-pin").get_attribute("aria-pressed") == "true"

    await page.locator("button.md-drawer-pin").click()
    await page.wait_for_timeout(300)
    restored = await page.evaluate(
        """() => ({
          checked: document.querySelector('#__drawer').checked,
          stored: localStorage.getItem('llm-infra-wiki:desktop-drawer-pinned'),
          geometry: {
            header: (() => { const b = document.querySelector('.md-header').getBoundingClientRect(); return {x:b.x,width:b.width} })(),
            main: (() => { const b = document.querySelector('.md-main').getBoundingClientRect(); return {x:b.x,width:b.width} })()
          }
        })"""
    )
    assert restored == {
        "checked": False,
        "stored": None,
        "geometry": {
            "header": {"x": 0, "width": 1440},
            "main": {"x": 0, "width": 1440},
        },
    }, restored

    await open_drawer(page)
    title_source = await page.evaluate(
        """() => {
          const title = document.querySelector('.md-nav--primary > .md-nav__title')
          const source = document.querySelector('.md-nav--primary > .md-nav__source')
          return {
            shadow: getComputedStyle(title).boxShadow,
            gap: source.getBoundingClientRect().top - title.getBoundingClientRect().bottom
          }
        }"""
    )
    assert title_source == {"shadow": "none", "gap": 0}, title_source

    await page.locator('label.md-nav__link[for="__nav_3"]').click()
    await page.wait_for_timeout(300)
    child = page.locator('nav[aria-labelledby="__nav_3_label"]')
    await child.locator("> label.md-nav__title").click()
    await page.wait_for_timeout(30)
    closing = await child.evaluate(
        """e => ({
          visibility: getComputedStyle(e).visibility,
          x: e.getBoundingClientRect().x,
          width: e.getBoundingClientRect().width
        })"""
    )
    assert closing["visibility"] == "visible", closing
    assert 0 < closing["x"] < closing["width"], closing

    await page.wait_for_timeout(300)
    closed = await child.evaluate(
        """e => ({
          visibility: getComputedStyle(e).visibility,
          opacity: getComputedStyle(e).opacity,
          x: e.getBoundingClientRect().x,
          width: e.getBoundingClientRect().width
        })"""
    )
    assert closed["visibility"] == "visible", closed
    assert closed["opacity"] == "0", closed
    assert closed["x"] >= closed["width"] - 1, closed

    if screenshot:
        await page.screenshot(path=str(screenshot), full_page=False)


async def verify_mobile(page: Page, url: str) -> None:
    await page.goto(url, wait_until="networkidle")
    await page.evaluate("localStorage.removeItem('llm-infra-wiki:desktop-drawer-pinned')")
    await page.reload(wait_until="networkidle")
    assert await page.locator("button.md-drawer-pin").count() == 0
    await open_drawer(page)
    drawer = await page.locator(".md-sidebar--primary").bounding_box()
    assert drawer == {"x": 0, "y": 0, "width": 242, "height": 900}, drawer
    geometry = await layout_geometry(page)
    assert geometry["header"] == {"x": 0, "width": 375}, geometry
    assert geometry["main"] == {"x": 0, "width": 375}, geometry

    await page.locator('a.md-nav__link[href$="/00-roadmap/"]').first.click()
    await page.wait_for_timeout(700)
    assert page.url.endswith("/00-roadmap/"), page.url
    assert not await page.locator("#__drawer").is_checked()


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:8000/")
    parser.add_argument("--browser-executable")
    parser.add_argument("--screenshot", type=Path)
    args = parser.parse_args()

    launch_options: dict[str, object] = {"headless": True, "args": ["--no-sandbox"]}
    if args.browser_executable:
        launch_options["executable_path"] = args.browser_executable

    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(**launch_options)
        desktop = await browser.new_page(viewport={"width": 1440, "height": 900})
        mobile = await browser.new_page(viewport={"width": 375, "height": 900})
        try:
            await verify_desktop(desktop, args.url, args.screenshot)
            await verify_mobile(mobile, args.url)
        finally:
            await browser.close()

    print("desktop/mobile drawer browser regression: PASS")


if __name__ == "__main__":
    asyncio.run(main())
