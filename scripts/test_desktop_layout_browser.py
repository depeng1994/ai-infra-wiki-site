#!/usr/bin/env python3
"""Browser regression checks for the desktop mobile-style drawer."""

from __future__ import annotations

import argparse
import asyncio
from pathlib import Path

from playwright.async_api import Page, async_playwright


async def open_drawer(page: Page) -> None:
    await page.locator('label.md-header__button[for="__drawer"]').click()
    await page.wait_for_timeout(300)


async def verify_desktop(page: Page, url: str, screenshot: Path | None) -> None:
    await page.goto(url, wait_until="networkidle")

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
    overlay = await page.locator(".md-overlay").bounding_box()
    assert drawer == {"x": 0, "y": 0, "width": 242, "height": 900}, drawer
    assert overlay == {"x": 0, "y": 0, "width": 1440, "height": 900}, overlay

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
    await open_drawer(page)
    drawer = await page.locator(".md-sidebar--primary").bounding_box()
    assert drawer == {"x": 0, "y": 0, "width": 242, "height": 900}, drawer


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
