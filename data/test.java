package vazkii.pie;

import java.awt.Color;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.FontRenderer;
import net.minecraft.client.renderer.Tessellator;

import org.lwjgl.opengl.GL11;
import org.lwjgl.opengl.GL12;
import org.lwjgl.util.vector.Vector2f;

public final class PieChartRenderer {
	
	public static List<Entry> entries = new ArrayList();

	public static class Entry {
		int val;
		int color;
		
		Entry(int val, int color) {
			this.val = val;
			this.color = color;
		}
	}
	
	public static void buildEntries() {
		entries.clear();
		
		List<Entry> rawEntries = new ArrayList();
		registerRawEntryData(rawEntries);
	
		int totalValue = 0;
		for(Entry entry : rawEntries)
			totalValue += entry.val;
		
		float mult = 360F / (float) totalValue;
		for(Entry entry : rawEntries) {
			entry.val = Math.round(entry.val * mult);
			entries.add(entry);
		}
	}
	
	// TODO, Temp, hardcoding is bad
	private static void registerRawEntryData(List<Entry> list) {
		list.add(new Entry(3000, 0xFF0000));
		list.add(new Entry(2100, 0xFF00FF));
		list.add(new Entry(1400, 0x00FF00));
		list.add(new Entry(2000, 0x0000FF));
		list.add(new Entry(1900, 0xFFFF00));
	}
	
	public static void renderChart(int radius, int x, int y, int mouseX, int mouseY, Collection<Entry> entries) {
		GL11.glPushMatrix();
		GL11.glDisable(GL11.GL_TEXTURE_2D);
		
		Entry tooltip = null;
        int tooltipDeg = 0;
		boolean mouseIn = (x - mouseX) * (x - mouseX) + (y - mouseY) * (y - mouseY) <= radius * radius;
		float angle = mouseAngle(x, y, mouseX, mouseY);
		int sectorHighlight = radius / 12;
		
		GL11.glShadeModel(GL11.GL_SMOOTH);
		int totalDeg = 0;
		for(Entry entry : entries) {
			boolean mouseInSector = mouseIn && angle >= totalDeg && angle < totalDeg + entry.val;

			Color color = new Color(entry.color);
						
			if(mouseInSector) {
				tooltip = entry;
				tooltipDeg = totalDeg;
				
				radius += sectorHighlight;
			}

			renderChartSection(color, x, y, radius, totalDeg, entry.val);
			
			if(mouseInSector)
				radius -= sectorHighlight;
			
			GL11.glColor4f(1F, 1F, 1F, 1F);

			totalDeg += entry.val;
		}
		
		
		GL11.glLineWidth(2F);
		GL11.glColor4f(0F, 0F, 0F, 1F);
		totalDeg = 0;
		for(Entry entry : entries) {
			boolean mouseInSector = mouseIn && angle >= totalDeg && angle < totalDeg + entry.val;
						
			if(mouseInSector)
				radius += sectorHighlight;
			
			float rad = (float) ((totalDeg) / 180F * Math.PI);
			
			GL11.glBegin(GL11.GL_LINES);
			GL11.glVertex2d(x, y);
			GL11.glVertex2d(x + Math.cos(rad) * radius, y + Math.sin(rad) * radius);
			GL11.glEnd();
			
			if(mouseInSector)
				radius -= sectorHighlight;

			totalDeg += entry.val;
		}
		GL11.glShadeModel(GL11.GL_FLAT);
		
		GL11.glLineWidth(3F);
		GL11.glColor4f(0F, 0F, 0F, 1F);
		GL11.glBegin(GL11.GL_LINE_LOOP);

		totalDeg = 0;
		for(int i = 0; i < 360; i++) {
			boolean sectorHighlighted = tooltip != null && i >= tooltipDeg && i < tooltip.val + tooltipDeg;
			boolean first = tooltip != null && i - tooltipDeg == 0;
			boolean last = tooltip != null &&  i - (tooltipDeg + tooltip.val) == -1;

			if(first)
				addVertexForAngle(x, y, i, radius);

			if(sectorHighlighted)
				radius += sectorHighlight;
			
			addVertexForAngle(x, y, i, radius);
			if(last)
				addVertexForAngle(x, y, i + 1, radius);
			
			if(sectorHighlighted)
				radius -= sectorHighlight;
			
			++totalDeg;
		}
		GL11.glEnd();
		
		GL11.glColor4f(1F, 1F, 1F, 1F);
		GL11.glEnable(GL11.GL_TEXTURE_2D);
		
		if(tooltip != null)
			renderTooltip(mouseX, mouseY, 1347420415, -267386864, Arrays.asList((int) Math.round((tooltip.val / 3.6)) + "%"));
		
		GL11.glPopMatrix();
	}
	
	private static void addVertexForAngle(int x, int y, int angle, int radius) {
		double rad = angle / 180F * Math.PI;
		double cos = Math.cos(rad);
		double sin = Math.sin(rad);
		
		GL11.glVertex2d(x + cos * radius, y + sin * radius);
	}
	
	private static float mouseAngle(int x, int y, int mx, int my) {
		Vector2f baseVec = new Vector2f(1F, 0F);
		Vector2f mouseVec = new Vector2f(mx - x, my - y);
		float ang = (float) (Math.acos(Vector2f.dot(baseVec, mouseVec) / (baseVec.length() * mouseVec.length())) * (180F / Math.PI));
		return my < y ? 360F - ang : ang;
	}
	
	private static void renderChartSection(Color color, int x, int y, int radius, int startDeg, int amplitude) {
		Color color1 = color.darker().darker();
		GL11.glBegin(GL11.GL_TRIANGLE_FAN);
		
		GL11.glColor4ub((byte) color.getRed(), (byte) color.getGreen(), (byte) color.getBlue(), (byte) 255);
		GL11.glVertex2i(x, y);			
		
		for(int i = amplitude; i >= 0; i--) {
			GL11.glColor4ub((byte) color1.getRed(), (byte) color1.getGreen(), (byte) color1.getBlue(), (byte) 255);
			float rad = (float) ((i + startDeg) / 180F * Math.PI);
			GL11.glVertex2d(x + Math.cos(rad) * radius, y + Math.sin(rad) * radius);
		}
		
		GL11.glColor4ub((byte) 0, (byte) 0, (byte) 0, (byte) 255);
		GL11.glVertex2i(x, y);		
		GL11.glEnd();
	}
	
	// ==================== SEMI COPY PASTED VANILLA MINECRAFT CODE BELOW ===================================
	
	private static void renderTooltip(int x, int y, int color, int color2, List<String> tooltipData) {
		GL11.glPushMatrix();
		GL11.glDisable(GL12.GL_RESCALE_NORMAL);
		net.minecraft.client.renderer.RenderHelper.disableStandardItemLighting();
		GL11.glDisable(GL11.GL_LIGHTING);
		GL11.glDisable(GL11.GL_DEPTH_TEST);

		if (!tooltipData.isEmpty()) {
			int var5 = 0;
			int var6;
			int var7;
			FontRenderer fontRenderer = Minecraft.getMinecraft().fontRenderer;
			for (var6 = 0; var6 < tooltipData.size(); ++var6) {
				var7 = fontRenderer.getStringWidth(tooltipData.get(var6));
				if (var7 > var5)
					var5 = var7;
			}
			var6 = x + 12;
			var7 = y - 12;
			int var9 = 8;
			if (tooltipData.size() > 1)
				var9 += 2 + (tooltipData.size() - 1) * 10;
			float z = 300.0F;
			drawGradientRect(var6 - 3, var7 - 4, z, var6 + var5 + 3, var7 - 3, color2, color2);
			drawGradientRect(var6 - 3, var7 + var9 + 3, z, var6 + var5 + 3, var7 + var9 + 4, color2, color2);
			drawGradientRect(var6 - 3, var7 - 3, z, var6 + var5 + 3, var7 + var9 + 3, color2, color2);
			drawGradientRect(var6 - 4, var7 - 3, z, var6 - 3, var7 + var9 + 3, color2, color2);
			drawGradientRect(var6 + var5 + 3, var7 - 3, z, var6 + var5 + 4, var7 + var9 + 3, color2, color2);
			int var12 = (color & 0xFFFFFF) >> 1 | color & -16777216;
			drawGradientRect(var6 - 3, var7 - 3 + 1, z, var6 - 3 + 1, var7 + var9 + 3 - 1, color, var12);
			drawGradientRect(var6 + var5 + 2, var7 - 3 + 1, z, var6 + var5 + 3, var7 + var9 + 3 - 1, color, var12);
			drawGradientRect(var6 - 3, var7 - 3, z, var6 + var5 + 3, var7 - 3 + 1, color, color);
			drawGradientRect(var6 - 3, var7 + var9 + 2, z, var6 + var5 + 3, var7 + var9 + 3, var12, var12);
			for (int var13 = 0; var13 < tooltipData.size(); ++var13) {
				String var14 = tooltipData.get(var13);
				fontRenderer.drawStringWithShadow(var14, var6, var7, -1);
				if (var13 == 0)
					var7 += 2;
				var7 += 10;
			}
		}
		GL11.glPopMatrix();
	}

	private static void drawGradientRect(int par1, int par2, float z, int par3, int par4, int par5, int par6) {
		float var7 = (par5 >> 24 & 255) / 255.0F;
		float var8 = (par5 >> 16 & 255) / 255.0F;
		float var9 = (par5 >> 8 & 255) / 255.0F;
		float var10 = (par5 & 255) / 255.0F;
		float var11 = (par6 >> 24 & 255) / 255.0F;
		float var12 = (par6 >> 16 & 255) / 255.0F;
		float var13 = (par6 >> 8 & 255) / 255.0F;
		float var14 = (par6 & 255) / 255.0F;
		GL11.glDisable(GL11.GL_TEXTURE_2D);
		GL11.glEnable(GL11.GL_BLEND);
		GL11.glDisable(GL11.GL_ALPHA_TEST);
		GL11.glBlendFunc(GL11.GL_SRC_ALPHA, GL11.GL_ONE_MINUS_SRC_ALPHA);
		GL11.glShadeModel(GL11.GL_SMOOTH);
		Tessellator var15 = Tessellator.instance;
		var15.startDrawingQuads();
		var15.setColorRGBA_F(var8, var9, var10, var7);
		var15.addVertex(par3, par2, z);
		var15.addVertex(par1, par2, z);
		var15.setColorRGBA_F(var12, var13, var14, var11);
		var15.addVertex(par1, par4, z);
		var15.addVertex(par3, par4, z);
		var15.draw();
		GL11.glShadeModel(GL11.GL_FLAT);
		GL11.glDisable(GL11.GL_BLEND);
		GL11.glEnable(GL11.GL_ALPHA_TEST);
		GL11.glEnable(GL11.GL_TEXTURE_2D);
	}
}